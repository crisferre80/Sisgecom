import React, { useState, useEffect } from 'react';
import { 
  Package, 
  ShoppingCart, 
  DollarSign, 
  AlertTriangle,
  TrendingUp,
  Users,
  Calendar,
  Download
} from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts';
import { supabase } from '../lib/supabase';
import { DashboardStats } from '../types';

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats>({
    total_products: 0,
    low_stock_products: 0,
    total_sales_today: 0,
    total_revenue_today: 0,
    pending_transactions: 0
  });
  const [loading, setLoading] = useState(true);

  // Sample data for charts
  const salesData = [
    { name: 'Lun', ventas: 12, ingresos: 2400 },
    { name: 'Mar', ventas: 19, ingresos: 1398 },
    { name: 'Mié', ventas: 8, ingresos: 9800 },
    { name: 'Jue', ventas: 27, ingresos: 3908 },
    { name: 'Vie', ventas: 35, ingresos: 4800 },
    { name: 'Sáb', ventas: 45, ingresos: 3800 },
    { name: 'Dom', ventas: 22, ingresos: 4300 },
  ];

  const topProducts = [
    { name: 'Producto A', sales: 45, revenue: 2250 },
    { name: 'Producto B', sales: 38, revenue: 1900 },
    { name: 'Producto C', sales: 32, revenue: 1600 },
    { name: 'Producto D', sales: 28, revenue: 1400 },
    { name: 'Producto E', sales: 25, revenue: 1250 },
  ];

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      // Load products stats
      const { count: totalProducts } = await supabase
        .from('products')
        .select('*', { count: 'exact', head: true });

      const { count: lowStockProducts } = await supabase
        .from('products')
        .select('*', { count: 'exact', head: true })
        .lt('quantity', 'min_stock');

      // Load today's sales
      const today = new Date().toISOString().split('T')[0];
      const { data: todaySales } = await supabase
        .from('sales')
        .select('total')
        .gte('date', today)
        .eq('status', 'completed');

      const { count: pendingTransactions } = await supabase
        .from('transactions')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'pending');

      const totalSalesToday = todaySales?.length || 0;
      const totalRevenueToday = todaySales?.reduce((sum, sale) => sum + sale.total, 0) || 0;

      setStats({
        total_products: totalProducts || 0,
        low_stock_products: lowStockProducts || 0,
        total_sales_today: totalSalesToday,
        total_revenue_today: totalRevenueToday,
        pending_transactions: pendingTransactions || 0
      });
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const exportReport = () => {
    // Implementation for exporting daily/weekly reports
    const reportData = {
      date: new Date().toISOString(),
      stats: stats,
      sales_data: salesData,
      top_products: topProducts
    };
    
    const dataStr = JSON.stringify(reportData, null, 2);
    const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
    
    const exportFileDefaultName = `reporte_${new Date().toISOString().split('T')[0]}.json`;
    
    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', dataUri);
    linkElement.setAttribute('download', exportFileDefaultName);
    linkElement.click();
  };

  if (loading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-6">
          <div className="h-8 bg-gray-200 rounded w-1/4"></div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="h-32 bg-gray-200 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600 mt-1">Resumen general del sistema</p>
        </div>
        <div className="mt-4 sm:mt-0 flex space-x-3">
          <button
            onClick={exportReport}
            className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
          >
            <Download className="w-4 h-4 mr-2" />
            Exportar Reporte
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-sm p-6 border border-gray-200">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <Package className="h-8 w-8 text-blue-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Total Productos</p>
              <p className="text-2xl font-bold text-gray-900">{stats.total_products}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6 border border-gray-200">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <AlertTriangle className="h-8 w-8 text-red-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Stock Bajo</p>
              <p className="text-2xl font-bold text-gray-900">{stats.low_stock_products}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6 border border-gray-200">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <ShoppingCart className="h-8 w-8 text-green-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Ventas Hoy</p>
              <p className="text-2xl font-bold text-gray-900">{stats.total_sales_today}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6 border border-gray-200">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <DollarSign className="h-8 w-8 text-green-600" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Ingresos Hoy</p>
              <p className="text-2xl font-bold text-gray-900">${stats.total_revenue_today.toFixed(2)}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow-sm p-6 border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-gray-900">Ventas de la Semana</h3>
            <TrendingUp className="h-5 w-5 text-green-600" />
          </div>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={salesData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="ventas" fill="#2563eb" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6 border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-gray-900">Ingresos de la Semana</h3>
            <DollarSign className="h-5 w-5 text-green-600" />
          </div>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={salesData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Line type="monotone" dataKey="ingresos" stroke="#059669" strokeWidth={2} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Top Products */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Productos Más Vendidos</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Producto</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ventas</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ingresos</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {topProducts.map((product, index) => (
                <tr key={index} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{product.name}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{product.sales}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${product.revenue}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;