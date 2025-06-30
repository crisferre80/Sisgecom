import React, { useState } from 'react';
import {
  Building2,
  User,
  Save,
  Info,
  RefreshCw,
  AlertTriangle
} from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { useConfiguration } from '../hooks/useConfiguration';
import UserProfile from './UserProfile';

interface ConfigurationProps {}

const Configuration: React.FC<ConfigurationProps> = () => {
  const { user } = useAuth();
  const {
    // Company Settings
    companySettings,
    saveCompanySettings,
    // Inventory Alerts
    inventoryAlerts,
    resolveAlert,
    generateAlerts,
    // Loading state
    loading,
    error: configError
  } = useConfiguration();

  const [activeTab, setActiveTab] = useState('company');
  const [message, setMessage] = useState<{ type: 'success' | 'error' | 'info'; text: string } | null>(null);
  
  // Local state for forms
  const [companyForm, setCompanyForm] = useState(companySettings || {
    company_name: '',
    company_email: '',
    company_phone: '',
    company_address: '',
    company_city: '',
    company_postal_code: '',
    company_country: '',
    tax_id: '',
    logo_url: '',
    website: '',
    default_currency: 'USD',
    default_tax_rate: 0,
    invoice_prefix: 'INV-',
    invoice_counter: 1,
    receipt_prefix: 'REC-',
    receipt_counter: 1,
    updated_at: new Date().toISOString(),
    updated_by: user?.id || ''
  });

  // Update form when companySettings changes
  React.useEffect(() => {
    if (companySettings) {
      setCompanyForm(companySettings);
    }
  }, [companySettings]);

  const showMessage = (type: 'success' | 'error' | 'info', text: string) => {
    setMessage({ type, text });
    setTimeout(() => setMessage(null), 5000);
  };

  const handleSaveCompanySettings = async () => {
    try {
      await saveCompanySettings(companyForm);
      showMessage('success', 'Configuración de empresa guardada exitosamente');
    } catch (error) {
      showMessage('error', 'Error al guardar la configuración de empresa');
    }
  };

  const handleResolveAlert = async (alertId: string) => {
    try {
      await resolveAlert(alertId);
      showMessage('success', 'Alerta resuelta');
    } catch (error) {
      showMessage('error', 'Error al resolver alerta');
    }
  };

  const handleGenerateAlerts = async () => {
    try {
      await generateAlerts();
      showMessage('success', 'Alertas generadas');
    } catch (error) {
      showMessage('error', 'Error al generar alertas');
    }
  };

  const tabs = [
    { id: 'company', name: 'Empresa', icon: Building2 },
    { id: 'profile', name: 'Perfil de Usuario', icon: User },
    { id: 'alerts', name: 'Alertas', icon: AlertTriangle },
  ];

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Configuración del Sistema</h1>
          <p className="text-gray-600">Gestiona la configuración general del sistema</p>
        </div>
      </div>

      {/* Message Display */}
      {(message || configError) && (
        <div className={`mb-6 p-4 rounded-md flex items-center ${
          message?.type === 'success' || !configError ? 'bg-green-50 text-green-800' :
          message?.type === 'error' || configError ? 'bg-red-50 text-red-800' :
          'bg-blue-50 text-blue-800'
        }`}>
          <Info className="w-5 h-5 mr-2" />
          {message?.text || configError}
        </div>
      )}

      {/* Tabs */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === tab.id
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <tab.icon className="w-5 h-5 mr-2" />
              {tab.name}
            </button>
          ))}
        </nav>
      </div>

      {/* Company Settings Tab */}
      {activeTab === 'company' && (
        <div className="bg-white rounded-lg shadow-sm border p-6">
          <h2 className="text-xl font-semibold mb-4">Configuración de la Empresa</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Nombre de la Empresa *
              </label>
              <input
                type="text"
                value={companyForm.company_name}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, company_name: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Email de la Empresa *
              </label>
              <input
                type="email"
                value={companyForm.company_email}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, company_email: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Teléfono
              </label>
              <input
                type="tel"
                value={companyForm.company_phone}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, company_phone: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                ID Fiscal
              </label>
              <input
                type="text"
                value={companyForm.tax_id}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, tax_id: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Dirección
              </label>
              <input
                type="text"
                value={companyForm.company_address}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, company_address: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Ciudad
              </label>
              <input
                type="text"
                value={companyForm.company_city}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, company_city: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                País
              </label>
              <input
                type="text"
                value={companyForm.company_country}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, company_country: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Moneda por Defecto
              </label>
              <select
                value={companyForm.default_currency}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, default_currency: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="USD">USD - Dólar Estadounidense</option>
                <option value="EUR">EUR - Euro</option>
                <option value="MXN">MXN - Peso Mexicano</option>
                <option value="COP">COP - Peso Colombiano</option>
                <option value="ARS">ARS - Peso Argentino</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Tasa de Impuesto por Defecto (%)
              </label>
              <input
                type="number"
                min="0"
                max="100"
                step="0.01"
                value={companyForm.default_tax_rate}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, default_tax_rate: parseFloat(e.target.value) || 0 }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Prefijo de Factura
              </label>
              <input
                type="text"
                value={companyForm.invoice_prefix}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, invoice_prefix: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Prefijo de Recibo
              </label>
              <input
                type="text"
                value={companyForm.receipt_prefix}
                onChange={(e) => setCompanyForm(prev => ({ ...prev, receipt_prefix: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div className="mt-6 flex justify-end">
            <button
              onClick={handleSaveCompanySettings}
              disabled={loading}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              <Save className="w-4 h-4 mr-2" />
              {loading ? 'Guardando...' : 'Guardar Configuración'}
            </button>
          </div>
        </div>
      )}

      {/* User Profile Tab */}
      {activeTab === 'profile' && <UserProfile />}

      {/* Inventory Alerts Tab */}
      {activeTab === 'alerts' && (
        <div className="bg-white rounded-lg shadow-sm border p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold">Alertas de Inventario</h2>
            <button
              onClick={handleGenerateAlerts}
              disabled={loading}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              <RefreshCw className="w-4 h-4 mr-2" />
              Generar Alertas
            </button>
          </div>
          
          <div className="space-y-4">
            {inventoryAlerts.map((alert) => (
              <div key={alert.id} className={`border rounded-lg p-4 ${
                alert.alert_level === 'critical' ? 'border-red-200 bg-red-50' :
                alert.alert_level === 'warning' ? 'border-yellow-200 bg-yellow-50' :
                'border-blue-200 bg-blue-50'
              }`}>
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2">
                      <AlertTriangle className={`w-5 h-5 ${
                        alert.alert_level === 'critical' ? 'text-red-600' :
                        alert.alert_level === 'warning' ? 'text-yellow-600' :
                        'text-blue-600'
                      }`} />
                      <span className="font-medium">{alert.alert_type.replace('_', ' ').toUpperCase()}</span>
                      <span className="text-sm text-gray-500">
                        {alert.product?.name} ({alert.product?.barcode})
                      </span>
                    </div>
                    <p className="text-gray-700 mt-1">{alert.message}</p>
                    <p className="text-sm text-gray-500 mt-1">
                      {new Date(alert.created_at).toLocaleString()}
                    </p>
                  </div>
                  <button
                    onClick={() => handleResolveAlert(alert.id!)}
                    className="px-3 py-1 bg-green-600 text-white rounded-md hover:bg-green-700 text-sm"
                  >
                    Resolver
                  </button>
                </div>
              </div>
            ))}
            
            {inventoryAlerts.length === 0 && (
              <div className="text-center py-8 text-gray-500">
                <AlertTriangle className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                <p>No hay alertas pendientes</p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default Configuration;
