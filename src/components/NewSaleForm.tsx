import React, { useState, useEffect } from 'react';
import { Plus, Minus, Search, X, ShoppingCart, User, Calculator } from 'lucide-react';
import { Product, Customer, Sale, SaleItem } from '../types';
import { supabase } from '../lib/supabase';

interface NewSaleFormProps {
  onClose: () => void;
  onSaleCreated: (sale: Sale) => void;
}

const NewSaleForm: React.FC<NewSaleFormProps> = ({ onClose, onSaleCreated }) => {
  const [loading, setLoading] = useState(false);
  const [step, setStep] = useState<'items' | 'customer' | 'payment'>('items');
  
  // Estados para la venta
  const [saleItems, setSaleItems] = useState<SaleItem[]>([]);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [customerName, setCustomerName] = useState('');
  const [customerEmail, setCustomerEmail] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('cash');
  const [notes, setNotes] = useState('');
  const [discountAmount, setDiscountAmount] = useState(0);
  
  // Estados para búsqueda de productos
  const [productSearch, setProductSearch] = useState('');
  const [searchResults, setSearchResults] = useState<Product[]>([]);
  const [showProductSearch, setShowProductSearch] = useState(false);
  
  // Estados para búsqueda de clientes
  const [customerSearch, setCustomerSearch] = useState('');
  const [customerResults, setCustomerResults] = useState<Customer[]>([]);
  const [showCustomerSearch, setShowCustomerSearch] = useState(false);

  // Buscar productos
  const searchProducts = async (query: string) => {
    if (query.length < 2) {
      setSearchResults([]);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .or(`name.ilike.%${query}%,barcode.ilike.%${query}%`)
        .eq('is_active', true)
        .limit(10);

      if (error) throw error;
      setSearchResults(data || []);
    } catch (error) {
      console.error('Error searching products:', error);
    }
  };

  // Buscar clientes
  const searchCustomers = async (query: string) => {
    if (query.length < 2) {
      setCustomerResults([]);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('customers')
        .select('*')
        .or(`first_name.ilike.%${query}%,last_name.ilike.%${query}%,email.ilike.%${query}%`)
        .eq('is_active', true)
        .limit(10);

      if (error) throw error;
      setCustomerResults(data || []);
    } catch (error) {
      console.error('Error searching customers:', error);
    }
  };

  useEffect(() => {
    const delayedSearch = setTimeout(() => {
      searchProducts(productSearch);
    }, 300);

    return () => clearTimeout(delayedSearch);
  }, [productSearch]);

  useEffect(() => {
    const delayedSearch = setTimeout(() => {
      searchCustomers(customerSearch);
    }, 300);

    return () => clearTimeout(delayedSearch);
  }, [customerSearch]);

  // Agregar producto a la venta
  const addProduct = (product: Product) => {
    const existingItem = saleItems.find(item => item.product_id === product.id);
    
    if (existingItem) {
      setSaleItems(items =>
        items.map(item =>
          item.product_id === product.id
            ? { ...item, quantity: item.quantity + 1, line_total: (item.quantity + 1) * item.unit_price }
            : item
        )
      );
    } else {
      const newItem: SaleItem = {
        product_id: product.id,
        product_barcode: product.barcode,
        product_name: product.name,
        quantity: 1,
        unit_price: product.price,
        discount_percentage: 0,
        discount_amount: 0,
        tax_rate: 21,
        tax_amount: product.price * 0.21,
        line_total: product.price + (product.price * 0.21),
      };
      setSaleItems([...saleItems, newItem]);
    }
    
    setProductSearch('');
    setShowProductSearch(false);
  };

  // Actualizar cantidad de item
  const updateItemQuantity = (index: number, quantity: number) => {
    if (quantity <= 0) {
      setSaleItems(items => items.filter((_, i) => i !== index));
      return;
    }

    setSaleItems(items =>
      items.map((item, i) =>
        i === index
          ? {
              ...item,
              quantity,
              tax_amount: item.unit_price * quantity * (item.tax_rate / 100),
              line_total: (item.unit_price * quantity) + (item.unit_price * quantity * (item.tax_rate / 100))
            }
          : item
      )
    );
  };

  // Remover item
  const removeItem = (index: number) => {
    setSaleItems(items => items.filter((_, i) => i !== index));
  };

  // Calcular totales
  const subtotal = saleItems.reduce((sum, item) => sum + (item.unit_price * item.quantity), 0);
  const taxAmount = saleItems.reduce((sum, item) => sum + item.tax_amount, 0);
  const totalAmount = subtotal + taxAmount - discountAmount;

  // Crear venta
  const createSale = async () => {
    if (saleItems.length === 0) {
      alert('Agrega al menos un producto a la venta');
      return;
    }

    setLoading(true);
    try {
      // Crear la venta principal
      const { data: saleData, error: saleError } = await supabase
        .from('sales')
        .insert({
          customer_id: selectedCustomer?.id,
          customer_name: selectedCustomer ? `${selectedCustomer.first_name} ${selectedCustomer.last_name || ''}`.trim() : customerName,
          customer_email: selectedCustomer?.email || customerEmail,
          subtotal,
          tax_amount: taxAmount,
          discount_amount: discountAmount,
          total_amount: totalAmount,
          payment_method: paymentMethod,
          sale_status: 'confirmed',
          payment_status: 'completed',
          notes,
          created_by: (await supabase.auth.getUser()).data.user?.id
        })
        .select()
        .single();

      if (saleError) throw saleError;

      // Crear los items de la venta
      const saleItemsData = saleItems.map(item => ({
        sale_id: saleData.id,
        product_id: item.product_id,
        product_barcode: item.product_barcode,
        product_name: item.product_name,
        quantity: item.quantity,
        unit_price: item.unit_price,
        discount_percentage: item.discount_percentage,
        discount_amount: item.discount_amount,
        tax_rate: item.tax_rate,
        tax_amount: item.tax_amount,
        line_total: item.line_total
      }));

      const { error: itemsError } = await supabase
        .from('sale_items')
        .insert(saleItemsData);

      if (itemsError) throw itemsError;

      // Crear el pago
      const { error: paymentError } = await supabase
        .from('sale_payments')
        .insert({
          sale_id: saleData.id,
          payment_method: paymentMethod,
          amount: totalAmount,
          created_by: (await supabase.auth.getUser()).data.user?.id
        });

      if (paymentError) throw paymentError;

      onSaleCreated(saleData);
    } catch (error) {
      console.error('Error creating sale:', error);
      alert('Error al crear la venta');
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('es-ES', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg w-full max-w-6xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-bold">Nueva Venta</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <X className="h-6 w-6" />
          </button>
        </div>

        {/* Steps */}
        <div className="px-6 py-4 border-b">
          <div className="flex space-x-4">
            <button
              onClick={() => setStep('items')}
              className={`px-4 py-2 rounded-lg ${step === 'items' ? 'bg-blue-100 text-blue-700' : 'text-gray-500'}`}
            >
              1. Productos
            </button>
            <button
              onClick={() => setStep('customer')}
              className={`px-4 py-2 rounded-lg ${step === 'customer' ? 'bg-blue-100 text-blue-700' : 'text-gray-500'}`}
            >
              2. Cliente
            </button>
            <button
              onClick={() => setStep('payment')}
              className={`px-4 py-2 rounded-lg ${step === 'payment' ? 'bg-blue-100 text-blue-700' : 'text-gray-500'}`}
            >
              3. Pago
            </button>
          </div>
        </div>

        <div className="flex-1 flex overflow-hidden">
          {/* Main Content */}
          <div className="flex-1 p-6 overflow-y-auto">
            {step === 'items' && (
              <div className="space-y-6">
                {/* Product Search */}
                <div className="relative">
                  <div className="flex gap-2">
                    <div className="flex-1 relative">
                      <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
                      <input
                        type="text"
                        placeholder="Buscar producto por nombre o código de barras..."
                        className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        value={productSearch}
                        onChange={(e) => {
                          setProductSearch(e.target.value);
                          setShowProductSearch(true);
                        }}
                        onFocus={() => setShowProductSearch(true)}
                      />
                    </div>
                  </div>
                  
                  {/* Search Results */}
                  {showProductSearch && searchResults.length > 0 && (
                    <div className="absolute top-full left-0 right-0 bg-white border border-gray-300 rounded-lg shadow-lg mt-1 z-10 max-h-60 overflow-y-auto">
                      {searchResults.map((product) => (
                        <div
                          key={product.id}
                          className="p-3 hover:bg-gray-50 cursor-pointer border-b last:border-b-0"
                          onClick={() => addProduct(product)}
                        >
                          <div className="flex justify-between items-center">
                            <div>
                              <p className="font-medium">{product.name}</p>
                              <p className="text-sm text-gray-500">{product.barcode} - Stock: {product.quantity}</p>
                            </div>
                            <p className="font-bold text-blue-600">{formatCurrency(product.price)}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Sale Items */}
                <div className="space-y-2">
                  <h3 className="text-lg font-semibold">Productos en la venta</h3>
                  {saleItems.length === 0 ? (
                    <div className="text-center py-8 text-gray-500">
                      <ShoppingCart className="mx-auto h-12 w-12 mb-2" />
                      <p>No hay productos agregados</p>
                      <p className="text-sm">Busca y selecciona productos para agregar a la venta</p>
                    </div>
                  ) : (
                    <div className="space-y-2">
                      {saleItems.map((item, index) => (
                        <div key={index} className="bg-gray-50 p-4 rounded-lg">
                          <div className="flex justify-between items-center">
                            <div className="flex-1">
                              <p className="font-medium">{item.product_name}</p>
                              <p className="text-sm text-gray-500">{item.product_barcode}</p>
                            </div>
                            <div className="flex items-center space-x-2">
                              <button
                                onClick={() => updateItemQuantity(index, item.quantity - 1)}
                                className="p-1 text-red-600 hover:bg-red-50 rounded"
                              >
                                <Minus className="h-4 w-4" />
                              </button>
                              <span className="w-12 text-center font-medium">{item.quantity}</span>
                              <button
                                onClick={() => updateItemQuantity(index, item.quantity + 1)}
                                className="p-1 text-green-600 hover:bg-green-50 rounded"
                              >
                                <Plus className="h-4 w-4" />
                              </button>
                              <span className="w-20 text-right">{formatCurrency(item.unit_price)}</span>
                              <span className="w-20 text-right font-bold">{formatCurrency(item.line_total)}</span>
                              <button
                                onClick={() => removeItem(index)}
                                className="p-1 text-red-600 hover:bg-red-50 rounded ml-2"
                              >
                                <X className="h-4 w-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            )}

            {step === 'customer' && (
              <div className="space-y-6">
                <div className="flex items-center gap-2 mb-4">
                  <User className="h-5 w-5" />
                  <h3 className="text-lg font-semibold">Información del Cliente</h3>
                </div>

                {/* Customer Search */}
                <div className="relative">
                  <div className="flex gap-2">
                    <div className="flex-1 relative">
                      <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
                      <input
                        type="text"
                        placeholder="Buscar cliente registrado..."
                        className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        value={customerSearch}
                        onChange={(e) => {
                          setCustomerSearch(e.target.value);
                          setShowCustomerSearch(true);
                        }}
                        onFocus={() => setShowCustomerSearch(true)}
                      />
                    </div>
                  </div>
                  
                  {/* Customer Search Results */}
                  {showCustomerSearch && customerResults.length > 0 && (
                    <div className="absolute top-full left-0 right-0 bg-white border border-gray-300 rounded-lg shadow-lg mt-1 z-10 max-h-60 overflow-y-auto">
                      {customerResults.map((customer) => (
                        <div
                          key={customer.id}
                          className="p-3 hover:bg-gray-50 cursor-pointer border-b last:border-b-0"
                          onClick={() => {
                            setSelectedCustomer(customer);
                            setCustomerSearch(`${customer.first_name} ${customer.last_name || ''}`.trim());
                            setShowCustomerSearch(false);
                          }}
                        >
                          <div className="flex justify-between items-center">
                            <div>
                              <p className="font-medium">{customer.first_name} {customer.last_name}</p>
                              <p className="text-sm text-gray-500">{customer.email} - {customer.phone}</p>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Manual Customer Info */}
                <div className="border-t pt-4">
                  <p className="text-sm text-gray-600 mb-4">O ingresa los datos manualmente:</p>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Nombre del Cliente
                      </label>
                      <input
                        type="text"
                        value={selectedCustomer ? `${selectedCustomer.first_name} ${selectedCustomer.last_name || ''}`.trim() : customerName}
                        onChange={(e) => {
                          setCustomerName(e.target.value);
                          setSelectedCustomer(null);
                        }}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        placeholder="Nombre del cliente"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Email (opcional)
                      </label>
                      <input
                        type="email"
                        value={selectedCustomer?.email || customerEmail}
                        onChange={(e) => {
                          setCustomerEmail(e.target.value);
                          if (selectedCustomer) setSelectedCustomer(null);
                        }}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        placeholder="email@ejemplo.com"
                      />
                    </div>
                  </div>
                </div>
              </div>
            )}

            {step === 'payment' && (
              <div className="space-y-6">
                <div className="flex items-center gap-2 mb-4">
                  <Calculator className="h-5 w-5" />
                  <h3 className="text-lg font-semibold">Método de Pago</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Método de Pago
                    </label>
                    <select
                      value={paymentMethod}
                      onChange={(e) => setPaymentMethod(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="cash">Efectivo</option>
                      <option value="card">Tarjeta</option>
                      <option value="transfer">Transferencia</option>
                      <option value="check">Cheque</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Descuento (€)
                    </label>
                    <input
                      type="number"
                      value={discountAmount}
                      onChange={(e) => setDiscountAmount(Number(e.target.value) || 0)}
                      min="0"
                      step="0.01"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Notas (opcional)
                  </label>
                  <textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    rows={3}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="Notas adicionales sobre la venta..."
                  />
                </div>
              </div>
            )}
          </div>

          {/* Sidebar - Summary */}
          <div className="w-80 bg-gray-50 p-6 border-l">
            <h3 className="text-lg font-semibold mb-4">Resumen de Venta</h3>
            
            <div className="space-y-3">
              <div className="flex justify-between">
                <span>Subtotal:</span>
                <span>{formatCurrency(subtotal)}</span>
              </div>
              <div className="flex justify-between">
                <span>IVA (21%):</span>
                <span>{formatCurrency(taxAmount)}</span>
              </div>
              {discountAmount > 0 && (
                <div className="flex justify-between text-red-600">
                  <span>Descuento:</span>
                  <span>-{formatCurrency(discountAmount)}</span>
                </div>
              )}
              <div className="border-t pt-3">
                <div className="flex justify-between text-lg font-bold">
                  <span>Total:</span>
                  <span>{formatCurrency(totalAmount)}</span>
                </div>
              </div>
            </div>

            <div className="mt-6 space-y-2">
              <p className="text-sm text-gray-600">
                Productos: {saleItems.length}
              </p>
              <p className="text-sm text-gray-600">
                Cantidad total: {saleItems.reduce((sum, item) => sum + item.quantity, 0)}
              </p>
            </div>

            <div className="mt-8 space-y-2">
              {step !== 'payment' && (
                <button
                  onClick={() => {
                    if (step === 'items') setStep('customer');
                    else if (step === 'customer') setStep('payment');
                  }}
                  disabled={step === 'items' && saleItems.length === 0}
                  className="w-full bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
                >
                  Continuar
                </button>
              )}
              
              {step === 'payment' && (
                <button
                  onClick={createSale}
                  disabled={loading || saleItems.length === 0}
                  className="w-full bg-green-600 text-white py-3 rounded-lg hover:bg-green-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
                >
                  {loading ? 'Procesando...' : 'Completar Venta'}
                </button>
              )}
              
              <button
                onClick={onClose}
                className="w-full bg-gray-200 text-gray-800 py-3 rounded-lg hover:bg-gray-300"
              >
                Cancelar
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default NewSaleForm;
