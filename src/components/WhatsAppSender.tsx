import React, { useState, useEffect } from 'react';
import { X, MessageCircle, Send, Users, Phone, CheckCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { Payment, Customer, WhatsAppContact } from '../types';

interface WhatsAppSenderProps {
  payments: Payment[];
  onClose: () => void;
  onSent: () => void;
}

const WhatsAppSender: React.FC<WhatsAppSenderProps> = ({ payments, onClose, onSent }) => {
  const [loading, setLoading] = useState(false);
  const [contacts, setContacts] = useState<WhatsAppContact[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [selectedContacts, setSelectedContacts] = useState<string[]>([]);
  const [messageTemplate, setMessageTemplate] = useState('');
  const [messageType, setMessageType] = useState<'reminder' | 'overdue' | 'custom'>('reminder');

  useEffect(() => {
    loadCustomersAndContacts();
  }, []);

  useEffect(() => {
    const templates = {
      reminder: `Estimado/a {nombre},

Le recordamos que tiene un pago pendiente:
💰 Monto: ${payments.length > 0 ? '$' + payments[0].amount : '$XXX'}
📅 Vencimiento: {fecha_vencimiento}
📋 Concepto: {descripcion}

Puede realizar su pago a través de nuestras billeteras virtuales:
• Yape: [número]
• Plin: [número]
• Transferencia bancaria: [datos]

¡Gracias por su preferencia!`,
      
      overdue: `Estimado/a {nombre},

Su pago se encuentra VENCIDO:
💰 Monto: ${payments.length > 0 ? '$' + payments[0].amount : '$XXX'}
📅 Venció el: {fecha_vencimiento}
📋 Concepto: {descripcion}

⚠️ Le solicitamos regularizar su pago a la brevedad para evitar inconvenientes.

Métodos de pago disponibles:
• Yape: [número]
• Plin: [número]
• Transferencia bancaria: [datos]

Para cualquier consulta, contáctenos.`,
      
      custom: 'Escriba su mensaje personalizado...'
    };
    setMessageTemplate(templates[messageType]);
  }, [messageType, payments]);

  useEffect(() => {
    // Seleccionar automáticamente los contactos de los pagos
    const customerIds = payments.map(p => p.customer_id);
    const availableContactIds = contacts
      .filter(c => customerIds.includes(c.customer_id))
      .map(c => c.id!);
    setSelectedContacts(availableContactIds);
  }, [payments, contacts]);

  const loadCustomersAndContacts = async () => {
    try {
      // Cargar clientes
      const { data: customersData, error: customersError } = await supabase
        .from('customers')
        .select('*');

      if (customersError) throw customersError;
      setCustomers(customersData || []);

      // Cargar contactos de WhatsApp
      const { data: contactsData, error: contactsError } = await supabase
        .from('whatsapp_contacts')
        .select('*');

      if (contactsError) throw contactsError;
      setContacts(contactsData || []);
    } catch (error) {
      console.error('Error loading data:', error);
    }
  };

  const getCustomerByPayment = (payment: Payment) => {
    return customers.find(c => c.id === payment.customer_id);
  };

  const getContactByCustomer = (customerId: string) => {
    return contacts.find(c => c.customer_id === customerId);
  };

  const formatMessage = (template: string, payment: Payment) => {
    const customer = getCustomerByPayment(payment);
    return template
      .replace('{nombre}', customer?.name || payment.customer_name)
      .replace('{monto}', `$${payment.amount.toFixed(2)}`)
      .replace('{fecha_vencimiento}', new Date(payment.due_date).toLocaleDateString())
      .replace('{descripcion}', payment.description ?? '');
  };

  const handleSendMessages = async () => {
    if (selectedContacts.length === 0) {
      alert('Seleccione al menos un contacto para enviar mensajes');
      return;
    }

    setLoading(true);
    try {
      for (const contactId of selectedContacts) {
        const contact = contacts.find(c => c.id === contactId);
        const payment = payments.find(p => p.customer_id === contact?.customer_id);
        
        if (contact && payment) {
          const message = formatMessage(messageTemplate, payment);
          
          // Abrir WhatsApp Web
          const whatsappUrl = `https://wa.me/${contact.phone_number.replace(/\D/g, '')}?text=${encodeURIComponent(message)}`;
          window.open(whatsappUrl, '_blank');
          
          // Registrar el recordatorio enviado
          await supabase.from('payment_reminders').insert([{
            payment_id: payment.id,
            customer_id: payment.customer_id,
            reminder_type: 'whatsapp',
            message: message,
            sent_at: new Date().toISOString(),
            status: 'enviado'
          }]);

          // Actualizar contador de mensajes del contacto
          await supabase
            .from('whatsapp_contacts')
            .update({ 
              message_count: (contact.message_count || 0) + 1,
              last_message_sent: new Date().toISOString()
            })
            .eq('id', contactId);

          // Esperar un poco entre mensajes para no saturar
          await new Promise(resolve => setTimeout(resolve, 1000));
        }
      }

      alert(`Se abrieron ${selectedContacts.length} conversaciones de WhatsApp`);
      onSent();
    } catch (error) {
      console.error('Error sending messages:', error);
      alert('Error al procesar los mensajes');
    } finally {
      setLoading(false);
    }
  };

  const addNewContact = async () => {
    const phone = prompt('Ingrese el número de teléfono (con código de país):');
    if (!phone) return;

    const customerId = prompt('Seleccione el ID del cliente o ingrese uno nuevo:');
    if (!customerId) return;

    try {
      const { error } = await supabase.from('whatsapp_contacts').insert([{
        customer_id: customerId,
        phone_number: phone,
        is_verified: false,
        message_count: 0,
        created_at: new Date().toISOString()
      }]);

      if (error) throw error;
      
      await loadCustomersAndContacts();
      alert('Contacto agregado exitosamente');
    } catch (error) {
      console.error('Error adding contact:', error);
      alert('Error al agregar contacto');
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={onClose} />
        
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full">
          <div className="bg-white px-4 pt-5 pb-4 sm:p-6">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center">
                <MessageCircle className="h-6 w-6 text-green-600 mr-2" />
                <h3 className="text-lg font-medium text-gray-900">
                  Enviar Mensajes de WhatsApp
                </h3>
              </div>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-500"
              >
                <X className="h-6 w-6" />
              </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Panel izquierdo: Contactos */}
              <div>
                <div className="flex items-center justify-between mb-4">
                  <h4 className="text-md font-medium text-gray-900 flex items-center">
                    <Users className="h-5 w-5 mr-2" />
                    Contactos ({selectedContacts.length} seleccionados)
                  </h4>
                  <button
                    onClick={addNewContact}
                    className="text-sm text-blue-600 hover:text-blue-800"
                  >
                    + Agregar contacto
                  </button>
                </div>

                <div className="border border-gray-200 rounded-lg max-h-64 overflow-y-auto">
                  {payments.map((payment) => {
                    const contact = getContactByCustomer(payment.customer_id);
                    const isSelected = contact && selectedContacts.includes(contact.id!);

                    return (
                      <div key={payment.id} className="p-3 border-b border-gray-100 last:border-b-0">
                        <div className="flex items-center justify-between">
                          <div className="flex-1">
                            <div className="font-medium text-gray-900">{payment.customer_name}</div>
                            <div className="text-sm text-gray-500">
                              ${payment.amount.toFixed(2)} - {new Date(payment.due_date).toLocaleDateString()}
                            </div>
                            {contact ? (
                              <div className="text-xs text-green-600 flex items-center">
                                <Phone className="h-3 w-3 mr-1" />
                                {contact.phone_number}
                                {contact.is_verified && <CheckCircle className="h-3 w-3 ml-1" />}
                              </div>
                            ) : (
                              <div className="text-xs text-red-500">Sin contacto de WhatsApp</div>
                            )}
                          </div>
                          
                          {contact && (
                            <input
                              type="checkbox"
                              checked={isSelected}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setSelectedContacts([...selectedContacts, contact.id!]);
                                } else {
                                  setSelectedContacts(selectedContacts.filter(id => id !== contact.id));
                                }
                              }}
                              className="rounded border-gray-300"
                            />
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Panel derecho: Mensaje */}
              <div>
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Tipo de mensaje
                  </label>
                  <select
                    value={messageType}
                    onChange={(e) => setMessageType(e.target.value as 'reminder' | 'overdue' | 'custom')}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="reminder">Recordatorio</option>
                    <option value="overdue">Pago vencido</option>
                    <option value="custom">Mensaje personalizado</option>
                  </select>
                </div>

                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Mensaje
                  </label>
                  <textarea
                    value={messageTemplate}
                    onChange={(e) => setMessageTemplate(e.target.value)}
                    rows={12}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 text-sm"
                    placeholder="Escriba su mensaje..."
                  />
                  <div className="text-xs text-gray-500 mt-1">
                    Variables disponibles: {'{nombre}'}, {'{monto}'}, {'{fecha_vencimiento}'}, {'{descripcion}'}
                  </div>
                </div>

                {payments.length > 0 && (
                  <div className="mb-4 p-3 bg-gray-50 rounded-lg">
                    <div className="text-sm font-medium text-gray-700 mb-2">Vista previa:</div>
                    <div className="text-xs text-gray-600 whitespace-pre-wrap bg-white p-2 rounded border">
                      {formatMessage(messageTemplate, payments[0])}
                    </div>
                  </div>
                )}
              </div>
            </div>

            <div className="mt-6 flex justify-between">
              <div className="text-sm text-gray-500">
                Se abrirán {selectedContacts.length} conversaciones de WhatsApp
              </div>
              
              <div className="flex space-x-3">
                <button
                  onClick={onClose}
                  className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                >
                  Cancelar
                </button>
                <button
                  onClick={handleSendMessages}
                  disabled={loading || selectedContacts.length === 0}
                  className="px-4 py-2 bg-green-600 text-white rounded-md text-sm font-medium hover:bg-green-700 disabled:opacity-50 flex items-center"
                >
                  {loading ? (
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                  ) : (
                    <Send className="h-4 w-4 mr-2" />
                  )}
                  Enviar Mensajes
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default WhatsAppSender;
