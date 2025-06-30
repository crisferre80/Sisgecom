import React, { useState, useEffect } from 'react';
import { X, Plus, Edit, Trash2, Smartphone, User, Phone, Mail } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { Customer, VirtualWallet } from '../types';

interface CustomerManagerProps {
  onClose: () => void;
  onCustomerCreated: () => void;
}

const CustomerManager: React.FC<CustomerManagerProps> = ({ onClose, onCustomerCreated }) => {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [wallets, setWallets] = useState<VirtualWallet[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCustomerForm, setShowCustomerForm] = useState(false);
  const [showWalletForm, setShowWalletForm] = useState(false);
  const [editingCustomer, setEditingCustomer] = useState<Customer | null>(null);
  const [editingWallet, setEditingWallet] = useState<VirtualWallet | null>(null);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);

  const [customerForm, setCustomerForm] = useState<{
    name: string;
    email: string;
    phone: string;
    address: string;
    status: 'active' | 'inactive' | 'blocked';
  }>({
    name: '',
    email: '',
    phone: '',
    address: '',
    status: 'active'
  });

  const [walletForm, setWalletForm] = useState<{
    customer_id: string;
    wallet_type: 'yape' | 'plin' | 'tunki' | 'mercado_pago' | 'banco_digital' | 'otro';
    wallet_identifier: string;
    alias: string;
    is_verified: boolean;
  }>({
    customer_id: '',
    wallet_type: 'yape',
    wallet_identifier: '',
    alias: '',
    is_verified: false
  });

  useEffect(() => {
    loadCustomers();
    loadWallets();
  }, []);

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
    } finally {
      setLoading(false);
    }
  };

  const loadWallets = async () => {
    try {
      const { data, error } = await supabase
        .from('virtual_wallets')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setWallets(data || []);
    } catch (error) {
      console.error('Error loading wallets:', error);
    }
  };

  const handleCustomerSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const customerData = {
        ...customerForm,
        created_at: new Date().toISOString()
      };

      if (editingCustomer) {
        const { error } = await supabase
          .from('customers')
          .update(customerData)
          .eq('id', editingCustomer.id);

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('customers')
          .insert([customerData]);

        if (error) throw error;
      }

      setShowCustomerForm(false);
      setEditingCustomer(null);
      setCustomerForm({
        name: '',
        email: '',
        phone: '',
        address: '',
        status: 'active'
      });
      
      await loadCustomers();
      onCustomerCreated();
    } catch (error) {
      console.error('Error saving customer:', error);
      alert('Error al guardar el cliente');
    } finally {
      setLoading(false);
    }
  };

  const handleWalletSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const walletData = {
        ...walletForm,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      if (editingWallet) {
        const { error } = await supabase
          .from('virtual_wallets')
          .update(walletData)
          .eq('id', editingWallet.id);

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('virtual_wallets')
          .insert([walletData]);

        if (error) throw error;
      }

      setShowWalletForm(false);
      setEditingWallet(null);
      setWalletForm({
        customer_id: '',
        wallet_type: 'yape',
        wallet_identifier: '',
        alias: '',
        is_verified: false
      });
      
      await loadWallets();
    } catch (error) {
      console.error('Error saving wallet:', error);
      alert('Error al guardar la billetera');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteCustomer = async (customerId: string) => {
    if (!window.confirm('¿Está seguro de que desea eliminar este cliente?')) return;

    try {
      const { error } = await supabase
        .from('customers')
        .delete()
        .eq('id', customerId);

      if (error) throw error;
      await loadCustomers();
    } catch (error) {
      console.error('Error deleting customer:', error);
      alert('Error al eliminar el cliente');
    }
  };

  const handleDeleteWallet = async (walletId: string) => {
    if (!window.confirm('¿Está seguro de que desea eliminar esta billetera?')) return;

    try {
      const { error } = await supabase
        .from('virtual_wallets')
        .delete()
        .eq('id', walletId);

      if (error) throw error;
      await loadWallets();
    } catch (error) {
      console.error('Error deleting wallet:', error);
      alert('Error al eliminar la billetera');
    }
  };

  const getCustomerWallets = (customerId: string) => {
    return wallets.filter(w => w.customer_id === customerId);
  };

  const walletTypes = [
    { value: 'yape', label: 'Yape', color: 'bg-purple-100 text-purple-800' },
    { value: 'plin', label: 'Plin', color: 'bg-blue-100 text-blue-800' },
    { value: 'tunki', label: 'Tunki', color: 'bg-orange-100 text-orange-800' },
    { value: 'mercado_pago', label: 'Mercado Pago', color: 'bg-cyan-100 text-cyan-800' },
    { value: 'banco_digital', label: 'Banco Digital', color: 'bg-green-100 text-green-800' },
    { value: 'otro', label: 'Otro', color: 'bg-gray-100 text-gray-800' }
  ];

  if (loading && customers.length === 0) {
    return (
      <div className="fixed inset-0 z-50 overflow-y-auto">
        <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20">
          <div className="bg-white rounded-lg p-6">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
            <p className="text-center mt-4">Cargando...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={onClose} />
        
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-6xl sm:w-full">
          <div className="bg-white px-4 pt-5 pb-4 sm:p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-medium text-gray-900">
                Gestión de Clientes y Billeteras
              </h3>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-500"
              >
                <X className="h-6 w-6" />
              </button>
            </div>

            <div className="flex space-x-4 mb-6">
              <button
                onClick={() => setShowCustomerForm(true)}
                className="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                <Plus className="h-4 w-4 mr-2" />
                Nuevo Cliente
              </button>
              <button
                onClick={() => setShowWalletForm(true)}
                className="inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
              >
                <Plus className="h-4 w-4 mr-2" />
                Nueva Billetera
              </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Lista de Clientes */}
              <div>
                <h4 className="text-md font-medium text-gray-900 mb-4">Clientes ({customers.length})</h4>
                <div className="space-y-3 max-h-96 overflow-y-auto">
                  {customers.map((customer) => (
                    <div
                      key={customer.id}
                      className={`p-4 border rounded-lg cursor-pointer transition-colors ${
                        selectedCustomer?.id === customer.id
                          ? 'border-blue-300 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                      onClick={() => setSelectedCustomer(customer)}
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center">
                            <User className="h-4 w-4 text-gray-500 mr-2" />
                            <span className="font-medium text-gray-900">{customer.name}</span>
                            <span className={`ml-2 px-2 py-1 text-xs rounded-full ${
                              customer.status === 'active'
                                ? 'bg-green-100 text-green-800'
                                : 'bg-red-100 text-red-800'
                            }`}>
                              {customer.status}
                            </span>
                          </div>
                          
                          <div className="mt-1 space-y-1">
                            <div className="flex items-center text-sm text-gray-600">
                              <Phone className="h-3 w-3 mr-1" />
                              {customer.phone}
                            </div>
                            {customer.email && (
                              <div className="flex items-center text-sm text-gray-600">
                                <Mail className="h-3 w-3 mr-1" />
                                {customer.email}
                              </div>
                            )}
                          </div>
                          
                          <div className="mt-2 text-sm">
                            <span className="text-gray-500">Deuda: </span>
                            <span className={`font-medium ${
                              customer.total_debt > 0 ? 'text-red-600' : 'text-green-600'
                            }`}>
                              ${customer.total_debt.toFixed(2)}
                            </span>
                          </div>
                          
                          <div className="mt-2">
                            <div className="text-xs text-gray-500">
                              Billeteras: {getCustomerWallets(customer.id!).length}
                            </div>
                            <div className="flex space-x-1 mt-1">
                              {getCustomerWallets(customer.id!).map((wallet) => {
                                const walletType = walletTypes.find(t => t.value === wallet.wallet_type);
                                return (
                                  <span
                                    key={wallet.id}
                                    className={`px-1 py-0.5 text-xs rounded ${walletType?.color || 'bg-gray-100 text-gray-800'}`}
                                  >
                                    {walletType?.label}
                                  </span>
                                );
                              })}
                            </div>
                          </div>
                        </div>
                        
                        <div className="flex space-x-1">
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              setEditingCustomer(customer);
                              setCustomerForm({
                                name: customer.name,
                                email: customer.email || '',
                                phone: customer.phone,
                                address: customer.address || '',
                                status: customer.status
                              });
                              setShowCustomerForm(true);
                            }}
                            className="text-blue-600 hover:text-blue-800"
                          >
                            <Edit className="h-4 w-4" />
                          </button>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleDeleteCustomer(customer.id!);
                            }}
                            className="text-red-600 hover:text-red-800"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Billeteras del Cliente Seleccionado */}
              <div>
                <h4 className="text-md font-medium text-gray-900 mb-4">
                  Billeteras {selectedCustomer && `de ${selectedCustomer.name}`}
                </h4>
                
                {selectedCustomer ? (
                  <div className="space-y-3 max-h-96 overflow-y-auto">
                    {getCustomerWallets(selectedCustomer.id!).map((wallet) => {
                      const walletType = walletTypes.find(t => t.value === wallet.wallet_type);
                      return (
                        <div key={wallet.id} className="p-4 border border-gray-200 rounded-lg">
                          <div className="flex items-start justify-between">
                            <div className="flex-1">
                              <div className="flex items-center">
                                <Smartphone className="h-4 w-4 text-gray-500 mr-2" />
                                <span className={`px-2 py-1 text-sm rounded ${walletType?.color}`}>
                                  {walletType?.label}
                                </span>
                                {wallet.is_verified && (
                                  <span className="ml-2 px-2 py-1 text-xs bg-green-100 text-green-800 rounded">
                                    Verificada
                                  </span>
                                )}
                              </div>
                              
                              <div className="mt-2 space-y-1">
                                <div className="text-sm text-gray-900 font-mono">
                                  {wallet.wallet_identifier}
                                </div>
                                {wallet.alias && (
                                  <div className="text-sm text-gray-600">
                                    Alias: {wallet.alias}
                                  </div>
                                )}
                              </div>
                            </div>
                            
                            <div className="flex space-x-1">
                              <button
                                onClick={() => {
                                  setEditingWallet(wallet);
                                  setWalletForm({
                                    customer_id: wallet.customer_id,
                                    wallet_type: wallet.wallet_type,
                                    wallet_identifier: wallet.wallet_identifier,
                                    alias: wallet.alias || '',
                                    is_verified: wallet.is_verified
                                  });
                                  setShowWalletForm(true);
                                }}
                                className="text-blue-600 hover:text-blue-800"
                              >
                                <Edit className="h-4 w-4" />
                              </button>
                              <button
                                onClick={() => handleDeleteWallet(wallet.id!)}
                                className="text-red-600 hover:text-red-800"
                              >
                                <Trash2 className="h-4 w-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                    
                    {getCustomerWallets(selectedCustomer.id!).length === 0 && (
                      <div className="text-center py-8 text-gray-500">
                        No hay billeteras registradas para este cliente
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="text-center py-8 text-gray-500">
                    Seleccione un cliente para ver sus billeteras
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Modal de Formulario de Cliente */}
      {showCustomerForm && (
        <div className="fixed inset-0 z-60 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75" onClick={() => setShowCustomerForm(false)} />
            
            <div className="bg-white rounded-lg p-6 w-full max-w-md z-10">
              <h4 className="text-lg font-medium mb-4">
                {editingCustomer ? 'Editar Cliente' : 'Nuevo Cliente'}
              </h4>
              
              <form onSubmit={handleCustomerSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Nombre *
                  </label>
                  <input
                    type="text"
                    value={customerForm.name}
                    onChange={(e) => setCustomerForm(prev => ({ ...prev, name: e.target.value }))}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Teléfono *
                  </label>
                  <input
                    type="tel"
                    value={customerForm.phone}
                    onChange={(e) => setCustomerForm(prev => ({ ...prev, phone: e.target.value }))}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Email
                  </label>
                  <input
                    type="email"
                    value={customerForm.email}
                    onChange={(e) => setCustomerForm(prev => ({ ...prev, email: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Dirección
                  </label>
                  <textarea
                    value={customerForm.address}
                    onChange={(e) => setCustomerForm(prev => ({ ...prev, address: e.target.value }))}
                    rows={2}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Estado
                  </label>
                  <select
                    value={customerForm.status}
                    onChange={(e) => setCustomerForm(prev => ({ ...prev, status: e.target.value as Customer['status'] }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="active">Activo</option>
                    <option value="inactive">Inactivo</option>
                    <option value="blocked">Bloqueado</option>
                  </select>
                </div>
                
                <div className="flex justify-end space-x-3 pt-4">
                  <button
                    type="button"
                    onClick={() => setShowCustomerForm(false)}
                    className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                  >
                    Cancelar
                  </button>
                  <button
                    type="submit"
                    disabled={loading}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
                  >
                    {loading ? 'Guardando...' : editingCustomer ? 'Actualizar' : 'Crear'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Modal de Formulario de Billetera */}
      {showWalletForm && (
        <div className="fixed inset-0 z-60 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75" onClick={() => setShowWalletForm(false)} />
            
            <div className="bg-white rounded-lg p-6 w-full max-w-md z-10">
              <h4 className="text-lg font-medium mb-4">
                {editingWallet ? 'Editar Billetera' : 'Nueva Billetera'}
              </h4>
              
              <form onSubmit={handleWalletSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Cliente *
                  </label>
                  <select
                    value={walletForm.customer_id}
                    onChange={(e) => setWalletForm(prev => ({ ...prev, customer_id: e.target.value }))}
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
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Tipo de billetera *
                  </label>
                  <select
                    value={walletForm.wallet_type}
                    onChange={(e) => setWalletForm(prev => ({ ...prev, wallet_type: e.target.value as VirtualWallet['wallet_type'] }))}
                    required
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  >
                    {walletTypes.map((type) => (
                      <option key={type.value} value={type.value}>
                        {type.label}
                      </option>
                    ))}
                  </select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Identificador *
                  </label>
                  <input
                    type="text"
                    value={walletForm.wallet_identifier}
                    onChange={(e) => setWalletForm(prev => ({ ...prev, wallet_identifier: e.target.value }))}
                    required
                    placeholder="Número de teléfono, email, etc."
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Alias
                  </label>
                  <input
                    type="text"
                    value={walletForm.alias}
                    onChange={(e) => setWalletForm(prev => ({ ...prev, alias: e.target.value }))}
                    placeholder="Nombre descriptivo"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    id="is_verified"
                    checked={walletForm.is_verified}
                    onChange={(e) => setWalletForm(prev => ({ ...prev, is_verified: e.target.checked }))}
                    className="rounded border-gray-300"
                  />
                  <label htmlFor="is_verified" className="ml-2 text-sm text-gray-700">
                    Billetera verificada
                  </label>
                </div>
                
                <div className="flex justify-end space-x-3 pt-4">
                  <button
                    type="button"
                    onClick={() => setShowWalletForm(false)}
                    className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                  >
                    Cancelar
                  </button>
                  <button
                    type="submit"
                    disabled={loading}
                    className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
                  >
                    {loading ? 'Guardando...' : editingWallet ? 'Actualizar' : 'Crear'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CustomerManager;
