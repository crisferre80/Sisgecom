import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { CompanySettings, SystemSettings, InventoryAlert, AuditLog } from '../types';

interface UseConfigurationReturn {
  // Company Settings
  companySettings: CompanySettings | null;
  loadCompanySettings: () => Promise<void>;
  saveCompanySettings: (settings: Partial<CompanySettings>) => Promise<void>;
  
  // System Settings
  systemSettings: SystemSettings[];
  loadSystemSettings: () => Promise<void>;
  saveSystemSetting: (setting: Partial<SystemSettings>) => Promise<void>;
  deleteSystemSetting: (id: string) => Promise<void>;
  getSetting: (key: string) => SystemSettings | undefined;
  getSettingValue: (key: string, defaultValue?: string) => string;
  
  // Inventory Alerts
  inventoryAlerts: InventoryAlert[];
  loadInventoryAlerts: () => Promise<void>;
  resolveAlert: (alertId: string) => Promise<void>;
  generateAlerts: () => Promise<void>;
  
  // Audit Logs
  auditLogs: AuditLog[];
  loadAuditLogs: () => Promise<void>;
  logAuditEvent: (
    action: string,
    entityType: string,
    entityId?: string,
    oldValues?: Record<string, unknown>,
    newValues?: Record<string, unknown>,
    details?: string
  ) => Promise<void>;
  
  // Loading states
  loading: boolean;
  error: string | null;
}

export const useConfiguration = (): UseConfigurationReturn => {
  const [companySettings, setCompanySettings] = useState<CompanySettings | null>(null);
  const [systemSettings, setSystemSettings] = useState<SystemSettings[]>([]);
  const [inventoryAlerts, setInventoryAlerts] = useState<InventoryAlert[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleError = (error: unknown, message: string) => {
    console.error(message, error);
    setError(message);
  };

  // Audit Logs - Declarar primero para evitar problemas de dependencias
  const logAuditEvent = useCallback(async (
    action: string,
    entityType: string,
    entityId?: string,
    oldValues?: Record<string, unknown>,
    newValues?: Record<string, unknown>,
    details?: string
  ) => {
    try {
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) return;

      const { error } = await supabase.rpc('log_audit_event', {
        p_user_id: user.user.id,
        p_user_email: user.user.email || '',
        p_action: action,
        p_entity_type: entityType,
        p_entity_id: entityId || null,
        p_old_values: oldValues || null,
        p_new_values: newValues || null,
        p_details: details || null
      });

      if (error) {
        console.error('Error logging audit event:', error);
      }
    } catch (error) {
      console.error('Error logging audit event:', error);
    }
  }, []);

  // Company Settings
  const loadCompanySettings = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const { data, error } = await supabase
        .from('company_settings')
        .select('*')
        .single();

      if (error && error.code !== 'PGRST116') {
        throw error;
      }

      setCompanySettings(data);
    } catch (error) {
      handleError(error, 'Error al cargar la configuración de empresa');
    } finally {
      setLoading(false);
    }
  }, []);

  const saveCompanySettings = useCallback(async (settings: Partial<CompanySettings>) => {
    try {
      setLoading(true);
      setError(null);

      const { data: user } = await supabase.auth.getUser();
      if (!user.user) throw new Error('Usuario no autenticado');

      const { error } = await supabase
        .from('company_settings')
        .upsert({
          ...settings,
          updated_at: new Date().toISOString(),
          updated_by: user.user.id
        });

      if (error) throw error;
      
      await loadCompanySettings();
      
      // Log audit event
      await logAuditEvent(
        'UPDATE',
        'company_settings',
        undefined,
        companySettings ? { ...companySettings } : undefined,
        settings,
        'Configuración de empresa actualizada'
      );
      
    } catch (error) {
      handleError(error, 'Error al guardar la configuración de empresa');
      throw error;
    } finally {
      setLoading(false);
    }
  }, [companySettings, loadCompanySettings, logAuditEvent]);

  // System Settings
  const loadSystemSettings = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const { data, error } = await supabase
        .from('system_settings')
        .select('*')
        .order('category', { ascending: true });

      if (error) throw error;
      setSystemSettings(data || []);
    } catch (error) {
      handleError(error, 'Error al cargar configuraciones del sistema');
    } finally {
      setLoading(false);
    }
  }, []);

  const saveSystemSetting = useCallback(async (setting: Partial<SystemSettings>) => {
    try {
      setLoading(true);
      setError(null);

      const { data: user } = await supabase.auth.getUser();
      if (!user.user) throw new Error('Usuario no autenticado');

      const { error } = await supabase
        .from('system_settings')
        .upsert({
          ...setting,
          updated_at: new Date().toISOString(),
          updated_by: user.user.id
        });

      if (error) throw error;
      
      await loadSystemSettings();
      
      // Log audit event
      await logAuditEvent(
        setting.id ? 'UPDATE' : 'CREATE',
        'system_settings',
        setting.id,
        undefined,
        setting,
        `Configuración del sistema ${setting.setting_key} ${setting.id ? 'actualizada' : 'creada'}`
      );
      
    } catch (error) {
      handleError(error, 'Error al guardar configuración del sistema');
      throw error;
    } finally {
      setLoading(false);
    }
  }, [loadSystemSettings, logAuditEvent]);

  const deleteSystemSetting = useCallback(async (id: string) => {
    try {
      setLoading(true);
      setError(null);

      const settingToDelete = systemSettings.find(s => s.id === id);
      
      const { error } = await supabase
        .from('system_settings')
        .delete()
        .eq('id', id);

      if (error) throw error;
      
      await loadSystemSettings();
      
      // Log audit event
      await logAuditEvent(
        'DELETE',
        'system_settings',
        id,
        settingToDelete ? { ...settingToDelete } : undefined,
        undefined,
        `Configuración del sistema ${settingToDelete?.setting_key} eliminada`
      );
      
    } catch (error) {
      handleError(error, 'Error al eliminar configuración del sistema');
      throw error;
    } finally {
      setLoading(false);
    }
  }, [loadSystemSettings, logAuditEvent, systemSettings]);

  const getSetting = useCallback((key: string): SystemSettings | undefined => {
    return systemSettings.find(setting => setting.setting_key === key);
  }, [systemSettings]);

  const getSettingValue = useCallback((key: string, defaultValue = ''): string => {
    const setting = getSetting(key);
    return setting ? setting.setting_value : defaultValue;
  }, [getSetting]);

  // Inventory Alerts
  const loadInventoryAlerts = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Primero verificar si la tabla existe
      const { data, error } = await supabase
        .from('inventory_alerts')
        .select(`
          *,
          product:products(name, barcode, quantity, min_stock)
        `)
        .eq('is_resolved', false)
        .order('created_at', { ascending: false });

      if (error) {
        // Manejo específico de errores comunes
        if (error.code === 'PGRST116' || error.message.includes('does not exist')) {
          handleError(error, 'La tabla inventory_alerts no existe. Debe aplicar las migraciones del módulo de configuración.');
        } else if (error.code === '42P01') {
          handleError(error, 'Error de base de datos: Tabla inventory_alerts no encontrada. Verifique las migraciones.');
        } else {
          handleError(error, `Error al cargar alertas de inventario: ${error.message}`);
        }
        return;
      }
      
      setInventoryAlerts(data || []);
    } catch (error) {
      handleError(error, 'Error inesperado al cargar alertas de inventario');
    } finally {
      setLoading(false);
    }
  }, []);

  const resolveAlert = useCallback(async (alertId: string) => {
    try {
      setLoading(true);
      setError(null);

      const { data: user } = await supabase.auth.getUser();
      if (!user.user) throw new Error('Usuario no autenticado');

      const { error } = await supabase
        .from('inventory_alerts')
        .update({
          is_resolved: true,
          resolved_at: new Date().toISOString(),
          resolved_by: user.user.id
        })
        .eq('id', alertId);

      if (error) throw error;
      
      await loadInventoryAlerts();
      
      // Log audit event
      await logAuditEvent(
        'UPDATE',
        'inventory_alerts',
        alertId,
        undefined,
        { is_resolved: true },
        'Alerta de inventario resuelta'
      );
      
    } catch (error) {
      handleError(error, 'Error al resolver alerta');
      throw error;
    } finally {
      setLoading(false);
    }
  }, [loadInventoryAlerts, logAuditEvent]);

  const generateAlerts = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const { error } = await supabase.rpc('generate_inventory_alerts');
      
      if (error) throw error;
      
      await loadInventoryAlerts();
    } catch (error) {
      handleError(error, 'Error al generar alertas');
      throw error;
    } finally {
      setLoading(false);
    }
  }, [loadInventoryAlerts]);

  // Audit Logs
  const loadAuditLogs = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const { data, error } = await supabase
        .from('audit_logs')
        .select('*')
        .order('timestamp', { ascending: false })
        .limit(100);

      if (error) throw error;
      setAuditLogs(data || []);
    } catch (error) {
      handleError(error, 'Error al cargar logs de auditoría');
    } finally {
      setLoading(false);
    }
  }, []);

  // Load initial data
  useEffect(() => {
    loadCompanySettings();
    loadSystemSettings();
    loadInventoryAlerts();
    loadAuditLogs();
  }, [loadCompanySettings, loadSystemSettings, loadInventoryAlerts, loadAuditLogs]);

  return {
    companySettings,
    loadCompanySettings,
    saveCompanySettings,
    systemSettings,
    loadSystemSettings,
    saveSystemSetting,
    deleteSystemSetting,
    getSetting,
    getSettingValue,
    inventoryAlerts,
    loadInventoryAlerts,
    resolveAlert,
    generateAlerts,
    auditLogs,
    loadAuditLogs,
    logAuditEvent,
    loading,
    error
  };
};
