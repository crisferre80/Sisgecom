import React from 'react';
import { X, Calendar, DollarSign, CreditCard, Edit, MessageCircle } from 'lucide-react';
import { Payment } from '../types';

interface PaymentDetailsProps {
  payment: Payment;
  onClose: () => void;
  onEdit: (payment: Payment) => void;
}

const PaymentDetails: React.FC<PaymentDetailsProps> = ({ payment, onClose, onEdit }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pagado': return 'bg-green-100 text-green-800';
      case 'pendiente': return 'bg-yellow-100 text-yellow-800';
      case 'vencido': return 'bg-red-100 text-red-800';
      case 'cancelado': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pagado': return '✅';
      case 'pendiente': return '⏳';
      case 'vencido': return '⚠️';
      case 'cancelado': return '❌';
      default: return '❓';
    }
  };

  const isOverdue = payment.status === 'pendiente' && new Date(payment.due_date) < new Date();

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={onClose} />
        
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
          <div className="bg-white px-4 pt-5 pb-4 sm:p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-medium text-gray-900">
                Detalles del Pago
              </h3>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-500"
              >
                <X className="h-6 w-6" />
              </button>
            </div>

            <div className="space-y-6">
              {/* Estado */}
              <div className="flex items-center justify-between p-4 rounded-lg border">
                <div className="flex items-center">
                  <span className="text-2xl mr-3">{getStatusIcon(payment.status)}</span>
                  <div>
                    <div className="font-medium text-gray-900">Estado del Pago</div>
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(payment.status)}`}>
                      {payment.status.toUpperCase()}
                    </span>
                  </div>
                </div>
                {isOverdue && (
                  <div className="text-right">
                    <div className="text-sm font-medium text-red-600">VENCIDO</div>
                    <div className="text-xs text-red-500">
                      {Math.ceil((new Date().getTime() - new Date(payment.due_date).getTime()) / (1000 * 60 * 60 * 24))} días
                    </div>
                  </div>
                )}
              </div>

              {/* Información del Cliente */}
              <div className="grid grid-cols-1 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Cliente</label>
                  <div className="mt-1 text-lg font-semibold text-gray-900">{payment.customer_name}</div>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Monto</label>
                    <div className="mt-1 flex items-center">
                      <DollarSign className="h-5 w-5 text-green-500 mr-1" />
                      <span className="text-xl font-bold text-gray-900">${payment.amount.toFixed(2)}</span>
                    </div>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Método de Pago</label>
                    <div className="mt-1 flex items-center">
                      <CreditCard className="h-4 w-4 text-gray-500 mr-1" />
                      <span className="text-sm text-gray-900 capitalize">{payment.payment_method}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Fechas */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Fecha de Vencimiento</label>
                  <div className="mt-1 flex items-center">
                    <Calendar className="h-4 w-4 text-gray-500 mr-1" />
                    <span className="text-sm text-gray-900">
                      {new Date(payment.due_date).toLocaleDateString()}
                    </span>
                  </div>
                </div>
                
                {payment.paid_date && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Fecha de Pago</label>
                    <div className="mt-1 flex items-center">
                      <Calendar className="h-4 w-4 text-green-500 mr-1" />
                      <span className="text-sm text-gray-900">
                        {new Date(payment.paid_date).toLocaleDateString()}
                      </span>
                    </div>
                  </div>
                )}
              </div>

              {/* Información adicional */}
              {payment.wallet_type && (
                <div>
                  <label className="block text-sm font-medium text-gray-700">Billetera Virtual</label>
                  <div className="mt-1 text-sm text-gray-900 capitalize">{payment.wallet_type}</div>
                </div>
              )}

              {payment.transaction_reference && (
                <div>
                  <label className="block text-sm font-medium text-gray-700">Referencia de Transacción</label>
                  <div className="mt-1 text-sm text-gray-900 font-mono">{payment.transaction_reference}</div>
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-gray-700">Descripción</label>
                <div className="mt-1 text-sm text-gray-900">{payment.description}</div>
              </div>

              {payment.notes && (
                <div>
                  <label className="block text-sm font-medium text-gray-700">Notas</label>
                  <div className="mt-1 text-sm text-gray-600 bg-gray-50 p-3 rounded-md">{payment.notes}</div>
                </div>
              )}

              {/* Información de auditoría */}
              <div className="pt-4 border-t border-gray-200">
                <div className="text-xs text-gray-500">
                  <div>Creado: {new Date(payment.created_at).toLocaleString()}</div>
                  <div>Actualizado: {new Date(payment.updated_at).toLocaleString()}</div>
                </div>
              </div>
            </div>

            {/* Acciones */}
            <div className="mt-6 flex justify-between">
              <div className="flex space-x-2">
                <button
                  onClick={() => window.open(`https://wa.me/1234567890?text=Estimado ${payment.customer_name}, le recordamos que tiene un pago pendiente de $${payment.amount} con vencimiento ${new Date(payment.due_date).toLocaleDateString()}.`)}
                  className="inline-flex items-center px-3 py-2 border border-green-300 rounded-md text-sm font-medium text-green-700 bg-white hover:bg-green-50"
                >
                  <MessageCircle className="h-4 w-4 mr-1" />
                  WhatsApp
                </button>
              </div>
              
              <div className="flex space-x-2">
                <button
                  onClick={() => onEdit(payment)}
                  className="inline-flex items-center px-4 py-2 border border-blue-300 rounded-md text-sm font-medium text-blue-700 bg-white hover:bg-blue-50"
                >
                  <Edit className="h-4 w-4 mr-1" />
                  Editar
                </button>
                <button
                  onClick={onClose}
                  className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                >
                  Cerrar
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PaymentDetails;
