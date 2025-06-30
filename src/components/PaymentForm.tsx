import React, { useState, useEffect } from 'react';
import { X, CreditCard, Smartphone, DollarSign } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { Payment, Customer, VirtualWallet } from '../types';
import { useAuth } from '../hooks/useAuth';

interface PaymentFormProps {
  payment?: Payment | null;
  customers: Customer[];
  onClose: () => void;
  onSave: () => void;
}

const PaymentForm: React.FC<PaymentFormProps> = ({ payment, customers, onClose, onSave }) => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [wallets, setWallets] = useState<VirtualWallet[]>([]);
  
  const [formData, setFormData] = useState({
    customer_id: '',
    customer_name: '',
    amount: '',
    payment_method: 'efectivo' as Payment['payment_method'],
    wallet_type: '',
    transaction_reference: '',
    status: 'pendiente' as Payment['status'],
    due_date: new Date().toISOString().split('T')[0],
    description: '',
    notes: ''
  });

  useEffect(() => {
    if (payment) {
      setFormData({
        customer_id: payment.customer_id,
        customer_name: payment.customer_name,
        amount: payment.amount.toString(),
        payment_method: payment.payment_method,
        wallet_type: payment.wallet_type || '',
        transaction_reference: payment.transaction_reference || '',
        status: payment.status,
        due_date: payment.due_date.split('T')[0],
        description: payment.description,
        notes: payment.notes || ''
      });
      
      // Buscar el cliente seleccionado
      const customer = customers.find(c => c.id === payment.customer_id);
      if (customer) {
        loadWallets(customer.id!);
      }
    }
  }, [payment, customers]);

  const loadWallets = async (customerId: string) => {
    try {
      const { data, error } = await supabase
        .from('virtual_wallets')
        .select('*')
        .eq('customer_id', customerId);

      if (error) throw error;
      setWallets(data || []);
    } catch (error) {
      console.error('Error loading wallets:', error);
    }
  };

  const handleCustomerSelect = (customerId: string) => {
    const customer = customers.find(c => c.id === customerId);
    if (customer) {
      setFormData(prev => ({
        ...prev,
        customer_id: customerId,
        customer_name: customer.name
      }));
      loadWallets(customerId);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const paymentData = {
        ...formData,
        amount: parseFloat(formData.amount),
        due_date: new Date(formData.due_date).toISOString(),
        updated_at: new Date().toISOString(),
        created_by: user?.id
      };

      if (payment?.id) {
        // Actualizar pago existente
        const { error } = await supabase
          .from('payments')
          .update(paymentData)
          .eq('id', payment.id);

        if (error) throw error;
      } else {
        // Crear nuevo pago
        const { error } = await supabase
          .from('payments')
          .insert([{
            ...paymentData,
            created_at: new Date().toISOString()
          }]);

        if (error) throw error;
      }

      onSave();
    } catch (error) {
      console.error('Error saving payment:', error);
      alert('Error al guardar el pago');
    } finally {
      setLoading(false);
    }
  };

  const paymentMethods = [
    { value: 'efectivo', label: 'Efectivo', icon: DollarSign },
    { value: 'tarjeta', label: 'Tarjeta', icon: CreditCard },
    { value: 'transferencia', label: 'Transferencia', icon: CreditCard },
    { value: 'billetera_virtual', label: 'Billetera Virtual', icon: Smartphone }
  ];

  const walletTypes = [
    { value: 'yape', label: 'Yape' },
    { value: 'plin', label: 'Plin' },
    { value: 'tunki', label: 'Tunki' },
    { value: 'mercado_pago', label: 'Mercado Pago' },
    { value: 'banco_digital', label: 'Banco Digital' },
    { value: 'otro', label: 'Otro' }
  ];

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={onClose} />
        
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-2xl sm:w-full">
          <form onSubmit={handleSubmit}>
            <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-lg font-medium text-gray-900">
                  {payment ? 'Editar Pago' : 'Nuevo Pago'}
                </h3>
                <button
                  type="button"
                  onClick={onClose}
                  className="text-gray-400 hover:text-gray-500"
                >
                  <X className="h-6 w-6" />
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Cliente */}
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Cliente *
                  </label>
                  <select
                    value={formData.customer_id}
                    onChange={(e) => handleCustomerSelect(e.target.value)}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="">Seleccionar cliente</option>
                    {customers.map((customer) => (
                      <option key={customer.id} value={customer.id}>
                        {customer.name} - {customer.phone}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Monto */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Monto *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={formData.amount}
                    onChange={(e) => setFormData(prev => ({ ...prev, amount: e.target.value }))}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                    placeholder="0.00"
                  />
                </div>

                {/* Fecha de vencimiento */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Fecha de vencimiento *
                  </label>
                  <input
                    type="date"
                    value={formData.due_date}
                    onChange={(e) => setFormData(prev => ({ ...prev, due_date: e.target.value }))}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>

                {/* Método de pago */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Método de pago *
                  </label>
                  <select
                    value={formData.payment_method}
                    onChange={(e) => setFormData(prev => ({ ...prev, payment_method: e.target.value as Payment['payment_method'] }))}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  >
                    {paymentMethods.map((method) => (
                      <option key={method.value} value={method.value}>
                        {method.label}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Tipo de billetera (solo si es billetera virtual) */}
                {formData.payment_method === 'billetera_virtual' && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Tipo de billetera
                    </label>
                    <select
                      value={formData.wallet_type}
                      onChange={(e) => setFormData(prev => ({ ...prev, wallet_type: e.target.value }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                    >
                      <option value="">Seleccionar tipo</option>
                      {walletTypes.map((type) => (
                        <option key={type.value} value={type.value}>
                          {type.label}
                        </option>
                      ))}
                    </select>
                    
                    {wallets.length > 0 && (
                      <div className="mt-2">
                        <p className="text-xs text-gray-500">Billeteras registradas:</p>
                        {wallets.map((wallet) => (
                          <div key={wallet.id} className="text-xs text-gray-600">
                            {wallet.wallet_type}: {wallet.wallet_identifier} 
                            {wallet.alias && ` (${wallet.alias})`}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                )}

                {/* Referencia de transacción */}
                {(formData.payment_method === 'transferencia' || formData.payment_method === 'billetera_virtual') && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Referencia de transacción
                    </label>
                    <input
                      type="text"
                      value={formData.transaction_reference}
                      onChange={(e) => setFormData(prev => ({ ...prev, transaction_reference: e.target.value }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                      placeholder="Número de operación"
                    />
                  </div>
                )}

                {/* Estado */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Estado *
                  </label>
                  <select
                    value={formData.status}
                    onChange={(e) => setFormData(prev => ({ ...prev, status: e.target.value as Payment['status'] }))}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="pendiente">Pendiente</option>
                    <option value="pagado">Pagado</option>
                    <option value="vencido">Vencido</option>
                    <option value="cancelado">Cancelado</option>
                  </select>
                </div>

                {/* Descripción */}
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Descripción *
                  </label>
                  <textarea
                    value={formData.description}
                    onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                    required
                    rows={3}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                    placeholder="Concepto del pago..."
                  />
                </div>

                {/* Notas */}
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Notas adicionales
                  </label>
                  <textarea
                    value={formData.notes}
                    onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
                    rows={2}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                    placeholder="Notas internas..."
                  />
                </div>
              </div>
            </div>

            <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
              <button
                type="submit"
                disabled={loading}
                className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm disabled:opacity-50"
              >
                {loading ? 'Guardando...' : payment ? 'Actualizar' : 'Crear'} Pago
              </button>
              <button
                type="button"
                onClick={onClose}
                className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:mt-0 sm:w-auto sm:text-sm"
              >
                Cancelar
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default PaymentForm;
