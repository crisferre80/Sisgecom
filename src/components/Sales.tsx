import React, { useState, useEffect } from 'react';
import { Plus, Search, FileText, RefreshCw, TrendingUp, DollarSign, ShoppingCart } from 'lucide-react';
import { Sale } from '../types';
import { supabase } from '../lib/supabase';
import NewSaleForm from './NewSaleForm';

const Sales: React.FC = () => {
  const [sales, setSales] = useState<Sale[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [showNewSaleModal, setShowNewSaleModal] = useState(false);
  const [selectedSale, setSelectedSale] = useState<Sale | null>(null);
  const [stats, setStats] = useState({
    totalSales: 0,
    totalRevenue: 0,
    pendingSales: 0,
    todaySales: 0
  });

  useEffect(() => {
    loadSales();
    loadStats();
  }, []);

  const loadSales = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('sales_complete')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setSales(data || []);
    } catch (error) {
      console.error('Error loading sales:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      // Obtener estadísticas básicas
      const { data: salesData, error: salesError } = await supabase
        .from('sales')
        .select('total_amount, sale_status, created_at')
        .eq('sale_status', 'confirmed');

      if (salesError) throw salesError;

      const today = new Date().toISOString().split('T')[0];
      const todaySales = salesData?.filter(sale => 
        sale.created_at.startsWith(today)
      ) || [];

      const totalRevenue = salesData?.reduce((sum, sale) => sum + sale.total_amount, 0) || 0;
      const todayRevenue = todaySales.reduce((sum, sale) => sum + sale.total_amount, 0);

      // Ventas pendientes
      const { data: pendingData, error: pendingError } = await supabase
        .from('sales')
        .select('id')
        .eq('sale_status', 'draft');

      if (pendingError) throw pendingError;

      setStats({
        totalSales: salesData?.length || 0,
        totalRevenue,
        pendingSales: pendingData?.length || 0,
        todaySales: todayRevenue
      });
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  };

  const filteredSales = sales.filter(sale => {
    const matchesSearch = 
      sale.sale_number.toLowerCase().includes(searchTerm.toLowerCase()) ||
      sale.customer_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      sale.customer_full_name?.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesFilter = filterStatus === 'all' || sale.sale_status === filterStatus;
    
    return matchesSearch && matchesFilter;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'text-yellow-600 bg-yellow-50';
      case 'confirmed': return 'text-green-600 bg-green-50';
      case 'delivered': return 'text-blue-600 bg-blue-50';
      case 'cancelled': return 'text-red-600 bg-red-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const getPaymentStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'text-yellow-600 bg-yellow-50';
      case 'partial': return 'text-orange-600 bg-orange-50';
      case 'completed': return 'text-green-600 bg-green-50';
      case 'refunded': return 'text-red-600 bg-red-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('es-ES', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('es-ES', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header with Image */}
      <div className="relative bg-gradient-to-r from-red-50 to-indigo-50 rounded-lg p-6 mb-6">
        <div className="flex justify-between items-center">
          <div className="flex items-center space-x-6">
            <div className="flex-shrink-0">
              <img 
                src="/Public/my assets/46171.jpg" 
                alt="Ventas" 
                className="w-20 h-20 object-cover rounded-lg shadow-md"
              />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Ventas</h1>
              <p className="text-gray-600">Gestión de ventas y facturación</p>
            </div>
          </div>
          <button
            onClick={() => setShowNewSaleModal(true)}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2"
          >
            <Plus className="h-5 w-5" />
            Nueva Venta
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-lg shadow">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Ventas Totales</p>
              <p className="text-2xl font-bold text-gray-900">{stats.totalSales}</p>
            </div>
            <ShoppingCart className="h-8 w-8 text-blue-600" />
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Ingresos Totales</p>
              <p className="text-2xl font-bold text-gray-900">{formatCurrency(stats.totalRevenue)}</p>
            </div>
            <DollarSign className="h-8 w-8 text-green-600" />
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Ventas Pendientes</p>
              <p className="text-2xl font-bold text-gray-900">{stats.pendingSales}</p>
            </div>
            <RefreshCw className="h-8 w-8 text-yellow-600" />
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Ventas Hoy</p>
              <p className="text-2xl font-bold text-gray-900">{formatCurrency(stats.todaySales)}</p>
            </div>
            <TrendingUp className="h-8 w-8 text-purple-600" />
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-lg shadow">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
              <input
                type="text"
                placeholder="Buscar por número de venta o cliente..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          <div className="flex gap-2">
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">Todos los estados</option>
              <option value="draft">Borrador</option>
              <option value="confirmed">Confirmado</option>
              <option value="delivered">Entregado</option>
              <option value="cancelled">Cancelado</option>
            </select>
            <button
              onClick={loadSales}
              className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 flex items-center gap-2"
            >
              <RefreshCw className="h-4 w-4" />
              Actualizar
            </button>
          </div>
        </div>
      </div>

      {/* Sales Table */}
      <div className="bg-white rounded-lg shadow">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Número de Venta
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Cliente
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Fecha
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Total
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Estado
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Pago
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Acciones
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredSales.map((sale) => (
                <tr key={sale.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {sale.sale_number}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {sale.customer_full_name || sale.customer_name || 'Cliente General'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {formatDate(sale.sale_date)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {formatCurrency(sale.total_amount)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(sale.sale_status)}`}>
                      {sale.sale_status === 'draft' && 'Borrador'}
                      {sale.sale_status === 'confirmed' && 'Confirmado'}
                      {sale.sale_status === 'delivered' && 'Entregado'}
                      {sale.sale_status === 'cancelled' && 'Cancelado'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getPaymentStatusColor(sale.payment_status)}`}>
                      {sale.payment_status === 'pending' && 'Pendiente'}
                      {sale.payment_status === 'partial' && 'Parcial'}
                      {sale.payment_status === 'completed' && 'Completado'}
                      {sale.payment_status === 'refunded' && 'Reembolsado'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex space-x-2">
                      <button
                        onClick={() => setSelectedSale(sale)}
                        className="text-blue-600 hover:text-blue-900"
                      >
                        Ver
                      </button>
                      <button className="text-green-600 hover:text-green-900">
                        <FileText className="h-4 w-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filteredSales.length === 0 && (
          <div className="text-center py-12">
            <ShoppingCart className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">No hay ventas</h3>
            <p className="mt-1 text-sm text-gray-500">
              Comienza creando tu primera venta.
            </p>
            <div className="mt-6">
              <button
                onClick={() => setShowNewSaleModal(true)}
                className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
              >
                <Plus className="h-4 w-4 mr-2" />
                Nueva Venta
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Modales */}
      {showNewSaleModal && (
        <NewSaleForm
          onClose={() => setShowNewSaleModal(false)}
          onSaleCreated={() => {
            loadSales();
            loadStats();
            setShowNewSaleModal(false);
          }}
        />
      )}

      {selectedSale && (
        <SaleDetailsModal
          sale={selectedSale}
          onClose={() => setSelectedSale(null)}
          onSaleUpdated={() => {
            loadSales();
            loadStats();
            setSelectedSale(null);
          }}
        />
      )}
    </div>
  );
};

// Componente modal para detalles de venta (placeholder)
const SaleDetailsModal: React.FC<{
  sale: Sale;
  onClose: () => void;
  onSaleUpdated: () => void;
}> = ({ sale, onClose }) => {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-4xl max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold">Detalles de Venta #{sale.sale_number}</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            ×
          </button>
        </div>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Cliente</label>
              <p className="text-sm text-gray-900">{sale.customer_full_name || sale.customer_name || 'Cliente General'}</p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Total</label>
              <p className="text-sm text-gray-900">{new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'EUR' }).format(sale.total_amount)}</p>
            </div>
          </div>
          <div className="mt-6 flex justify-end space-x-2">
            <button
              onClick={onClose}
              className="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300"
            >
              Cerrar
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Sales;
