import React from 'react';
import { Payment, Customer, VirtualWallet, PaymentSummary } from '../types';

// Test component para verificar que los tipos están correctos
const PaymentTest: React.FC = () => {
  // Test de tipos
  const testPayment: Payment = {
    id: 'test-id',
    customer_id: 'customer-1',
    customer_name: 'Test Customer',
    amount: 100.50,
    payment_method: 'billetera_virtual',
    wallet_type: 'yape',
    transaction_reference: 'TXN123',
    status: 'pendiente',
    due_date: '2025-01-15T00:00:00Z',
    description: 'Test payment',
    created_at: '2025-06-29T00:00:00Z',
    updated_at: '2025-06-29T00:00:00Z',
    created_by: 'user-1'
  };

  const testCustomer: Customer = {
    id: 'customer-1',
    name: 'Test Customer',
    phone: '+51987654321',
    email: 'test@example.com',
    created_at: '2025-06-29T00:00:00Z',
    total_debt: 100.50,
    status: 'active'
  };

  const testWallet: VirtualWallet = {
    id: 'wallet-1',
    customer_id: 'customer-1',
    wallet_type: 'yape',
    wallet_identifier: '+51987654321',
    alias: 'Mi Yape',
    is_verified: true,
    created_at: '2025-06-29T00:00:00Z',
    updated_at: '2025-06-29T00:00:00Z'
  };

  const testSummary: PaymentSummary = {
    total_pending: 500.00,
    total_paid: 1000.00,
    total_overdue: 200.00,
    pending_count: 5,
    paid_count: 10,
    overdue_count: 2,
    this_month_collected: 800.00,
    customers_with_debt: 3
  };

  return (
    <div className="p-4">
      <h2 className="text-xl font-bold mb-4">Test de Tipos del Módulo de Pagos</h2>
      
      <div className="space-y-4">
        <div className="bg-green-100 p-4 rounded">
          <h3 className="font-semibold">✅ Payment Type</h3>
          <p>ID: {testPayment.id}</p>
          <p>Cliente: {testPayment.customer_name}</p>
          <p>Monto: ${testPayment.amount}</p>
          <p>Estado: {testPayment.status}</p>
        </div>

        <div className="bg-blue-100 p-4 rounded">
          <h3 className="font-semibold">✅ Customer Type</h3>
          <p>ID: {testCustomer.id}</p>
          <p>Nombre: {testCustomer.name}</p>
          <p>Teléfono: {testCustomer.phone}</p>
          <p>Deuda: ${testCustomer.total_debt}</p>
        </div>

        <div className="bg-purple-100 p-4 rounded">
          <h3 className="font-semibold">✅ VirtualWallet Type</h3>
          <p>ID: {testWallet.id}</p>
          <p>Tipo: {testWallet.wallet_type}</p>
          <p>Identificador: {testWallet.wallet_identifier}</p>
          <p>Verificado: {testWallet.is_verified ? 'Sí' : 'No'}</p>
        </div>

        <div className="bg-yellow-100 p-4 rounded">
          <h3 className="font-semibold">✅ PaymentSummary Type</h3>
          <p>Total Pendiente: ${testSummary.total_pending}</p>
          <p>Total Pagado: ${testSummary.total_paid}</p>
          <p>Clientes con Deuda: {testSummary.customers_with_debt}</p>
        </div>
      </div>

      <div className="mt-6 p-4 bg-green-50 border border-green-200 rounded">
        <h3 className="font-semibold text-green-800">🎉 Todos los tipos se compilaron correctamente</h3>
        <p className="text-green-700 text-sm mt-1">
          El módulo de pagos con billeteras virtuales está listo para usar.
        </p>
      </div>
    </div>
  );
};

export default PaymentTest;
