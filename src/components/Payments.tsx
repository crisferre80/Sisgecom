import React, { useState, useEffect } from 'react';
import { 
  Users, 
  DollarSign, 
  AlertTriangle,
  Plus,
  Search,
  MessageCircle,
  Calendar,
  Eye,
  Edit,
  Trash2
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { Payment, PaymentSummary, Customer } from '../types';
import PaymentForm from './PaymentForm.tsx';
import PaymentDetails from './PaymentDetails.tsx';
import WhatsAppSender from './WhatsAppSender.tsx';
import CustomerManager from './CustomerManager.tsx';

const Payments: React.FC = () => {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [summary, setSummary] = useState<PaymentSummary>({
    total_pending: 0,
    total_paid: 0,
    total_overdue: 0,
    pending_count: 0,
    paid_count: 0,
    overdue_count: 0,
    this_month_collected: 0,
    customers_with_debt: 0
  });
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('todos');
  const [showPaymentForm, setShowPaymentForm] = useState(false);
  const [showPaymentDetails, setShowPaymentDetails] = useState<Payment | null>(null);
  const [showWhatsAppSender, setShowWhatsAppSender] = useState(false);
  const [showCustomerManager, setShowCustomerManager] = useState(false);
  const [editingPayment, setEditingPayment] = useState<Payment | null>(null);
  const [selectedPayments, setSelectedPayments] = useState<string[]>([]);

  useEffect(() => {
    loadPayments();
    loadCustomers();
    loadSummary();
  }, []);

  const loadPayments = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('payments')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setPayments(data || []);
    } catch (error) {
      console.error('Error loading payments:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadCustomers = async () => {
    try {
      const { data, error } = await supabase
        .from('customers')
        .select('*')
        .order('name');

      if (error) throw error;
      setCustomers(data || []);
    } catch (error) {
      console.error('Error loading customers:', error);
    }
  };

  const loadSummary = async () => {
    try {
      // Cargar resumen de pagos
      const { data: paymentsData, error: paymentsError } = await supabase
        .from('payments')
        .select('amount, status, created_at, paid_date');

      if (paymentsError) throw paymentsError;

      const today = new Date();
      const thisMonth = new Date(today.getFullYear(), today.getMonth(), 1);
      const now = new Date();

      const summaryData = paymentsData?.reduce((acc, payment) => {
        const paymentDate = new Date(payment.created_at);
        const paidDate = payment.paid_date ? new Date(payment.paid_date) : null;

        if (payment.status === 'pendiente') {
          acc.total_pending += payment.amount;
          acc.pending_count++;
          
          // Verificar si está vencido
          if (paymentDate < now) {
            acc.total_overdue += payment.amount;
            acc.overdue_count++;
          }
        } else if (payment.status === 'pagado') {
          acc.total_paid += payment.amount;
          acc.paid_count++;
          
          // Pagos de este mes
          if (paidDate && paidDate >= thisMonth) {
            acc.this_month_collected += payment.amount;
          }
        }

        return acc;
      }, {
        total_pending: 0,
        total_paid: 0,
        total_overdue: 0,
        pending_count: 0,
        paid_count: 0,
        overdue_count: 0,
        this_month_collected: 0,
        customers_with_debt: 0
      });

      // Contar clientes con deuda
      const { count: debtorsCount } = await supabase
        .from('customers')
        .select('*', { count: 'exact', head: true })
        .gt('total_debt', 0);

      setSummary({
        ...summaryData,
        customers_with_debt: debtorsCount || 0
      });
    } catch (error) {
      console.error('Error loading summary:', error);
    }
  };

  const filteredPayments = payments.filter(payment => {
    const matchesSearch = payment.customer_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         payment.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'todos' || payment.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getOverduePayments = () => {
    const now = new Date();
    return filteredPayments.filter(payment => 
      payment.status === 'pendiente' && new Date(payment.due_date) < now
    );
  };

  const handleDeletePayment = async (paymentId: string) => {
    if (!window.confirm('¿Está seguro de que desea eliminar este pago?')) return;

    try {
      const { error } = await supabase
        .from('payments')
        .delete()
        .eq('id', paymentId);

      if (error) throw error;
      
      await loadPayments();
      await loadSummary();
    } catch (error) {
      console.error('Error deleting payment:', error);
    }
  };

  const handleBulkWhatsApp = () => {
    if (selectedPayments.length === 0) {
      alert('Seleccione al menos un pago para enviar mensajes');
      return;
    }
    setShowWhatsAppSender(true);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pagado': return 'bg-green-100 text-green-800';
      case 'pendiente': return 'bg-yellow-100 text-yellow-800';
      case 'vencido': return 'bg-red-100 text-red-800';
      case 'cancelado': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Gestión de Pagos</h1>
          <p className="text-gray-600 mt-1">Monitoreo de pagos y billeteras virtuales</p>
        </div>
        <div className="mt-4 sm:mt-0 flex space-x-3">
          <button
            onClick={() => setShowCustomerManager(true)}
            className="inline-flex items-center px-4 py-2 border border-purple-300 rounded-md shadow-sm text-sm font-medium text-purple-700 bg-white hover:bg-purple-50"
          >
            <Users className="w-4 h-4 mr-2" />
            Clientes
          </button>
          <button
            onClick={() => setShowWhatsAppSender(true)}
            className="inline-flex items-center px-4 py-2 border border-green-300 rounded-md shadow-sm text-sm font-medium text-green-700 bg-white hover:bg-green-50"
          >
            <MessageCircle className="w-4 h-4 mr-2" />
            WhatsApp
          </button>
          <button
            onClick={() => setShowPaymentForm(true)}
            className="inline-flex items-center px-4 py-2 bg-blue-600 border border-transparent rounded-md shadow-sm text-sm font-medium text-white hover:bg-blue-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Nuevo Pago
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <DollarSign className="h-6 w-6 text-green-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Total Cobrado</dt>
                  <dd className="text-lg font-medium text-gray-900">${summary.total_paid.toFixed(2)}</dd>
                </dl>
              </div>
            </div>
          </div>
          <div className="bg-gray-50 px-5 py-3">
            <div className="text-sm">
              <span className="text-green-600 font-medium">{summary.paid_count}</span>
              <span className="text-gray-500"> pagos completados</span>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <AlertTriangle className="h-6 w-6 text-yellow-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Pendientes</dt>
                  <dd className="text-lg font-medium text-gray-900">${summary.total_pending.toFixed(2)}</dd>
                </dl>
              </div>
            </div>
          </div>
          <div className="bg-gray-50 px-5 py-3">
            <div className="text-sm">
              <span className="text-yellow-600 font-medium">{summary.pending_count}</span>
              <span className="text-gray-500"> pagos pendientes</span>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Calendar className="h-6 w-6 text-red-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Vencidos</dt>
                  <dd className="text-lg font-medium text-gray-900">${summary.total_overdue.toFixed(2)}</dd>
                </dl>
              </div>
            </div>
          </div>
          <div className="bg-gray-50 px-5 py-3">
            <div className="text-sm">
              <span className="text-red-600 font-medium">{summary.overdue_count}</span>
              <span className="text-gray-500"> pagos vencidos</span>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Users className="h-6 w-6 text-blue-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Deudores</dt>
                  <dd className="text-lg font-medium text-gray-900">{summary.customers_with_debt}</dd>
                </dl>
              </div>
            </div>
          </div>
          <div className="bg-gray-50 px-5 py-3">
            <div className="text-sm">
              <span className="text-blue-600 font-medium">${summary.this_month_collected.toFixed(2)}</span>
              <span className="text-gray-500"> este mes</span>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white shadow rounded-lg p-6">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-4 sm:space-y-0">
          <div className="flex-1 max-w-md">
            <div className="relative">
              <Search className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Buscar por cliente o descripción..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 pr-4 py-2 w-full border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>
          
          <div className="flex space-x-3">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="todos">Todos los estados</option>
              <option value="pendiente">Pendientes</option>
              <option value="pagado">Pagados</option>
              <option value="vencido">Vencidos</option>
              <option value="cancelado">Cancelados</option>
            </select>
            
            {selectedPayments.length > 0 && (
              <button
                onClick={handleBulkWhatsApp}
                className="inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
              >
                <MessageCircle className="w-4 h-4 mr-2" />
                Enviar WhatsApp ({selectedPayments.length})
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Payments Table */}
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  <input
                    type="checkbox"
                    onChange={(e) => {
                      if (e.target.checked) {
                        setSelectedPayments(filteredPayments.map(p => p.id!));
                      } else {
                        setSelectedPayments([]);
                      }
                    }}
                    className="rounded border-gray-300"
                  />
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Cliente
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Monto
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Estado
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Vencimiento
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Método
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Acciones
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredPayments.map((payment) => (
                <tr key={payment.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <input
                      type="checkbox"
                      checked={selectedPayments.includes(payment.id!)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedPayments([...selectedPayments, payment.id!]);
                        } else {
                          setSelectedPayments(selectedPayments.filter(id => id !== payment.id));
                        }
                      }}
                      className="rounded border-gray-300"
                    />
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{payment.customer_name}</div>
                    <div className="text-sm text-gray-500">{payment.description}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">${payment.amount.toFixed(2)}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(payment.status)}`}>
                      {payment.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">
                      {new Date(payment.due_date).toLocaleDateString()}
                    </div>
                    {new Date(payment.due_date) < new Date() && payment.status === 'pendiente' && (
                      <div className="text-xs text-red-500">Vencido</div>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{payment.payment_method}</div>
                    {payment.wallet_type && (
                      <div className="text-xs text-gray-500">{payment.wallet_type}</div>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex space-x-2">
                      <button
                        onClick={() => setShowPaymentDetails(payment)}
                        className="text-blue-600 hover:text-blue-900"
                        title="Ver detalles"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => setEditingPayment(payment)}
                        className="text-yellow-600 hover:text-yellow-900"
                        title="Editar"
                      >
                        <Edit className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDeletePayment(payment.id!)}
                        className="text-red-600 hover:text-red-900"
                        title="Eliminar"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modals */}
      {showPaymentForm && (
        <PaymentForm
          payment={editingPayment}
          customers={customers}
          onClose={() => {
            setShowPaymentForm(false);
            setEditingPayment(null);
          }}
          onSave={() => {
            setShowPaymentForm(false);
            setEditingPayment(null);
            loadPayments();
            loadSummary();
          }}
        />
      )}

      {showPaymentDetails && (
        <PaymentDetails
          payment={showPaymentDetails}
          onClose={() => setShowPaymentDetails(null)}
          onEdit={(payment: Payment) => {
            setShowPaymentDetails(null);
            setEditingPayment(payment);
            setShowPaymentForm(true);
          }}
        />
      )}

      {showWhatsAppSender && (
        <WhatsAppSender
          payments={selectedPayments.length > 0 ? 
            filteredPayments.filter(p => selectedPayments.includes(p.id!)) : 
            getOverduePayments()
          }
          onClose={() => setShowWhatsAppSender(false)}
          onSent={() => {
            setShowWhatsAppSender(false);
            setSelectedPayments([]);
          }}
        />
      )}

      {showCustomerManager && (
        <CustomerManager
          onClose={() => setShowCustomerManager(false)}
          onCustomerCreated={() => {
            setShowCustomerManager(false);
            loadCustomers();
          }}
        />
      )}
    </div>
  );
};

export default Payments;
