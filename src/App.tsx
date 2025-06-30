import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './hooks/useAuth';
import ProtectedRoute from './components/ProtectedRoute';
import Layout from './components/Layout';
import Dashboard from './components/Dashboard';
import Inventory from './components/Inventory';
import Payments from './components/Payments';
import UserManagement from './components/UserManagement';
import Login from './components/Login';

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/*"
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Dashboard />} />
            <Route path="inventory" element={<Inventory />} />
            <Route path="sales" element={<div className="p-6"><h1 className="text-2xl font-bold">Módulo de Ventas</h1><p className="text-gray-600">Próximamente...</p></div>} />
            <Route path="payments" element={<Payments />} />
            <Route path="users" element={<UserManagement />} />
            <Route path="settings" element={<div className="p-6"><h1 className="text-2xl font-bold">Configuración</h1><p className="text-gray-600">Próximamente...</p></div>} />
          </Route>
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;