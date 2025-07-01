import React, { useState } from 'react';
import {
  Building2,
  User,
  Save
} from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { useConfiguration } from '../hooks/useConfiguration';
import UserProfile from './UserProfile';

// eslint-disable-next-line @typescript-eslint/no-empty-object-type
interface ConfigurationProps {}

const Configuration: React.FC<ConfigurationProps> = () => {
  const { user } = useAuth();
  const {
    // Company Settings
    companySettings,
    saveCompanySettings,
    // Loading state
    loading
  } = useConfiguration();

  const [activeTab, setActiveTab] = useState('company');
  
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

  const handleSaveCompanySettings = async () => {
    try {
      await saveCompanySettings(companyForm);
    } catch {
      // Error handling removed
    }
  };

  const tabs = [
    { id: 'company', name: 'Empresa', icon: Building2 },
    { id: 'profile', name: 'Perfil de Usuario', icon: User },
  ];

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Configuración del Sistema</h1>
          <p className="text-gray-600">Gestiona la configuración general del sistema</p>
        </div>
      </div>

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
    </div>
  );
};

export default Configuration;
