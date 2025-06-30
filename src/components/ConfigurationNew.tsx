import React, { useState } from 'react';
import {
  Settings,
  Building2,
  Bell,
  Shield,
  Database,
  AlertTriangle,
  Save,
  Eye,
  EyeOff,
  Copy,
  Check,
  Info,
  Trash2,
  Plus,
  RefreshCw
} from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { useConfiguration } from '../hooks/useConfiguration';
import type { SystemSettings } from '../types';

interface ConfigurationProps {}

const Configuration: React.FC<ConfigurationProps> = () => {
  const { user } = useAuth();
  const {
    // Company Settings
    companySettings,
    saveCompanySettings,
    // System Settings
    systemSettings,
    saveSystemSetting,
    deleteSystemSetting,
    // Inventory Alerts
    inventoryAlerts,
    resolveAlert,
    generateAlerts,
    // Audit Logs
    auditLogs,
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

  const [newSetting, setNewSetting] = useState<Partial<SystemSettings>>({
    setting_key: '',
    setting_value: '',
    setting_type: 'string',
    description: '',
    category: 'general',
    is_public: false
  });

  // Security settings state
  const [showApiKeys, setShowApiKeys] = useState(false);
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

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

  const handleAddSystemSetting = async () => {
    if (!newSetting.setting_key || !newSetting.setting_value) {
      showMessage('error', 'Clave y valor son requeridos');
      return;
    }

    try {
      await saveSystemSetting(newSetting);
      setNewSetting({
        setting_key: '',
        setting_value: '',
        setting_type: 'string',
        description: '',
        category: 'general',
        is_public: false
      });
      showMessage('success', 'Configuración del sistema agregada');
    } catch (error) {
      showMessage('error', 'Error al agregar configuración del sistema');
    }
  };

  const handleDeleteSystemSetting = async (id: string) => {
    if (!confirm('¿Estás seguro de que quieres eliminar esta configuración?')) {
      return;
    }

    try {
      await deleteSystemSetting(id);
      showMessage('success', 'Configuración eliminada');
    } catch (error) {
      showMessage('error', 'Error al eliminar configuración');
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

  const copyToClipboard = async (text: string, keyName: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedKey(keyName);
      setTimeout(() => setCopiedKey(null), 2000);
    } catch (error) {
      console.error('Error copying to clipboard:', error);
    }
  };

  const tabs = [
    { id: 'company', name: 'Empresa', icon: Building2 },
    { id: 'system', name: 'Sistema', icon: Settings },
    { id: 'notifications', name: 'Notificaciones', icon: Bell },
    { id: 'security', name: 'Seguridad', icon: Shield },
    { id: 'backups', name: 'Respaldos', icon: Database },
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

      {/* System Settings Tab */}
      {activeTab === 'system' && (
        <div className="bg-white rounded-lg shadow-sm border p-6">
          <h2 className="text-xl font-semibold mb-4">Configuración del Sistema</h2>
          
          {/* Add New Setting */}
          <div className="bg-gray-50 p-4 rounded-lg mb-6">
            <h3 className="text-lg font-medium mb-3">Agregar Nueva Configuración</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <input
                type="text"
                placeholder="Clave de configuración"
                value={newSetting.setting_key}
                onChange={(e) => setNewSetting(prev => ({ ...prev, setting_key: e.target.value }))}
                className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <input
                type="text"
                placeholder="Valor"
                value={newSetting.setting_value}
                onChange={(e) => setNewSetting(prev => ({ ...prev, setting_value: e.target.value }))}
                className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <select
                value={newSetting.category}
                onChange={(e) => setNewSetting(prev => ({ ...prev, category: e.target.value as any }))}
                className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="general">General</option>
                <option value="inventory">Inventario</option>
                <option value="sales">Ventas</option>
                <option value="payments">Pagos</option>
                <option value="notifications">Notificaciones</option>
                <option value="security">Seguridad</option>
              </select>
            </div>
            <div className="mt-4 flex justify-end">
              <button
                onClick={handleAddSystemSetting}
                disabled={loading}
                className="flex items-center px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
              >
                <Plus className="w-4 h-4 mr-2" />
                Agregar
              </button>
            </div>
          </div>

          {/* Settings List */}
          <div className="space-y-4">
            {systemSettings.map((setting) => (
              <div key={setting.id} className="border border-gray-200 rounded-lg p-4">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2">
                      <span className="font-medium">{setting.setting_key}</span>
                      <span className={`px-2 py-1 text-xs rounded-full ${
                        setting.category === 'general' ? 'bg-gray-100 text-gray-800' :
                        setting.category === 'inventory' ? 'bg-blue-100 text-blue-800' :
                        setting.category === 'sales' ? 'bg-green-100 text-green-800' :
                        setting.category === 'payments' ? 'bg-yellow-100 text-yellow-800' :
                        setting.category === 'notifications' ? 'bg-purple-100 text-purple-800' :
                        'bg-red-100 text-red-800'
                      }`}>
                        {setting.category}
                      </span>
                    </div>
                    <p className="text-gray-600 mt-1">{setting.setting_value}</p>
                    {setting.description && (
                      <p className="text-sm text-gray-500 mt-1">{setting.description}</p>
                    )}
                  </div>
                  <button
                    onClick={() => handleDeleteSystemSetting(setting.id!)}
                    className="p-2 text-red-600 hover:bg-red-50 rounded-md"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

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

      {/* Security Tab */}
      {activeTab === 'security' && (
        <div className="bg-white rounded-lg shadow-sm border p-6">
          <h2 className="text-xl font-semibold mb-4">Configuración de Seguridad</h2>
          
          <div className="space-y-6">
            <div className="border border-gray-200 rounded-lg p-4">
              <h3 className="text-lg font-medium mb-3">Claves API</h3>
              <div className="space-y-3">
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-md">
                  <div>
                    <p className="font-medium">Supabase URL</p>
                    <p className="text-sm text-gray-600">
                      {showApiKeys ? import.meta.env.VITE_SUPABASE_URL : '••••••••••••••••'}
                    </p>
                  </div>
                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => setShowApiKeys(!showApiKeys)}
                      className="p-2 text-gray-500 hover:text-gray-700"
                    >
                      {showApiKeys ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                    <button
                      onClick={() => copyToClipboard(import.meta.env.VITE_SUPABASE_URL, 'url')}
                      className="p-2 text-gray-500 hover:text-gray-700"
                    >
                      {copiedKey === 'url' ? <Check className="w-4 h-4 text-green-600" /> : <Copy className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
                
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-md">
                  <div>
                    <p className="font-medium">Supabase Anon Key</p>
                    <p className="text-sm text-gray-600">
                      {showApiKeys ? import.meta.env.VITE_SUPABASE_ANON_KEY : '••••••••••••••••'}
                    </p>
                  </div>
                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => setShowApiKeys(!showApiKeys)}
                      className="p-2 text-gray-500 hover:text-gray-700"
                    >
                      {showApiKeys ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                    <button
                      onClick={() => copyToClipboard(import.meta.env.VITE_SUPABASE_ANON_KEY, 'anon')}
                      className="p-2 text-gray-500 hover:text-gray-700"
                    >
                      {copiedKey === 'anon' ? <Check className="w-4 h-4 text-green-600" /> : <Copy className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div className="border border-gray-200 rounded-lg p-4">
              <h3 className="text-lg font-medium mb-3">Logs de Auditoría</h3>
              <div className="space-y-2">
                {auditLogs.slice(0, 10).map((log) => (
                  <div key={log.id} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-b-0">
                    <div>
                      <span className="font-medium">{log.user_email}</span>
                      <span className="text-gray-600 ml-2">{log.action}</span>
                      <span className="text-gray-500 ml-2">en {log.entity_type}</span>
                    </div>
                    <span className="text-sm text-gray-500">
                      {new Date(log.timestamp).toLocaleString()}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Notifications Tab */}
      {activeTab === 'notifications' && (
        <div className="bg-white rounded-lg shadow-sm border p-6">
          <h2 className="text-xl font-semibold mb-4">Configuración de Notificaciones</h2>
          <div className="text-center py-8 text-gray-500">
            <Bell className="w-12 h-12 mx-auto mb-4 text-gray-300" />
            <p>Configuración de notificaciones próximamente...</p>
          </div>
        </div>
      )}

      {/* Backups Tab */}
      {activeTab === 'backups' && (
        <div className="bg-white rounded-lg shadow-sm border p-6">
          <h2 className="text-xl font-semibold mb-4">Configuración de Respaldos</h2>
          <div className="text-center py-8 text-gray-500">
            <Database className="w-12 h-12 mx-auto mb-4 text-gray-300" />
            <p>Configuración de respaldos próximamente...</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default Configuration;
