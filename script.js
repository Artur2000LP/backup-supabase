// Configuración global
let config = {
    githubToken: '',
    repoOwner: 'Artur2000LP', // Tu usuario de GitHub
    repoName: 'backup-supabase', // Tu repositorio
    apiBase: 'https://api.github.com'
};

// Estado de la aplicación
let appState = {
    connected: false,
    loading: false,
    backups: [],
    workflows: []
};

// Inicialización
document.addEventListener('DOMContentLoaded', function() {
    loadConfig();
    initializeApp();
    updateStatus();
    
    // Auto-refresh cada 30 segundos
    setInterval(updateStatus, 30000);
});

// Gestión de configuración
function loadConfig() {
    const saved = localStorage.getItem('supabaseBackupConfig');
    if (saved) {
        config = { ...config, ...JSON.parse(saved) };
        document.getElementById('githubToken').value = config.githubToken;
        document.getElementById('repoOwner').value = config.repoOwner;
        document.getElementById('repoName').value = config.repoName;
    }
}

function saveConfig() {
    const token = document.getElementById('githubToken').value.trim();
    const owner = document.getElementById('repoOwner').value.trim();
    const repo = document.getElementById('repoName').value.trim();
    
    if (!token || !owner || !repo) {
        showNotification('Por favor completa todos los campos', 'error');
        return;
    }
    
    config = { ...config, githubToken: token, repoOwner: owner, repoName: repo };
    localStorage.setItem('supabaseBackupConfig', JSON.stringify(config));
    
    showNotification('Configuración guardada correctamente', 'success');
    testConnection();
}

// Conexión y estado
async function testConnection() {
    if (!config.githubToken || !config.repoOwner || !config.repoName) {
        updateStatus('disconnected', 'Configuración incompleta');
        return;
    }
    
    updateStatus('connecting', 'Conectando...');
    
    try {
        const response = await githubAPI('GET', `/repos/${config.repoOwner}/${config.repoName}`);
        if (response.ok) {
            appState.connected = true;
            updateStatus('connected', 'Conectado');
            await loadWorkflows();
            await refreshHistory();
        } else {
            throw new Error('No se pudo conectar al repositorio');
        }
    } catch (error) {
        appState.connected = false;
        updateStatus('disconnected', 'Error de conexión: ' + error.message);
        logMessage('Error al conectar: ' + error.message, 'error');
    }
}

function updateStatus(status = 'disconnected', message = 'Desconectado') {
    const statusIcon = document.getElementById('statusIcon');
    const statusText = document.getElementById('statusText');
    
    statusIcon.className = `fas fa-circle ${status}`;
    statusText.textContent = message;
    
    // Actualizar estado de conexión
    if (status === 'connected') {
        appState.connected = true;
    } else if (status === 'disconnected') {
        appState.connected = false;
    }
}

// GitHub API
async function githubAPI(method, endpoint, data = null) {
    const url = `${config.apiBase}${endpoint}`;
    const options = {
        method: method,
        headers: {
            'Authorization': `token ${config.githubToken}`,
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json'
        }
    };
    
    if (data) {
        options.body = JSON.stringify(data);
    }
    
    try {
        const response = await fetch(url, options);
        return {
            ok: response.ok,
            status: response.status,
            data: await response.json()
        };
    } catch (error) {
        logMessage(`Error en API: ${error.message}`, 'error');
        throw error;
    }
}

// Workflows
async function loadWorkflows() {
    try {
        const response = await githubAPI('GET', `/repos/${config.repoOwner}/${config.repoName}/actions/workflows`);
        if (response.ok) {
            appState.workflows = response.data.workflows;
            logMessage('Workflows cargados correctamente', 'success');
        }
    } catch (error) {
        logMessage('Error al cargar workflows: ' + error.message, 'error');
    }
}

async function triggerBackup() {
    if (!appState.connected) {
        showNotification('No hay conexión con GitHub', 'error');
        return;
    }
    
    const backupWorkflow = appState.workflows.find(w => 
        w.name === 'respaldo-supabase' || w.name === 'supabase-backup'
    );
    
    if (!backupWorkflow) {
        showNotification('No se encontró el workflow de respaldo', 'error');
        return;
    }
    
    try {
        showNotification('Iniciando respaldo...', 'info');
        logMessage('Disparando workflow de respaldo manual', 'info');
        
        const response = await githubAPI('POST', 
            `/repos/${config.repoOwner}/${config.repoName}/actions/workflows/${backupWorkflow.id}/dispatches`,
            { ref: 'main' }
        );
        
        if (response.ok) {
            showNotification('Respaldo iniciado correctamente', 'success');
            logMessage('Workflow de respaldo disparado exitosamente', 'success');
            
            // Actualizar historial después de un momento
            setTimeout(refreshHistory, 3000);
        } else {
            throw new Error(`Error ${response.status}: ${response.data.message}`);
        }
    } catch (error) {
        showNotification('Error al iniciar respaldo: ' + error.message, 'error');
        logMessage('Error al disparar workflow: ' + error.message, 'error');
    }
}

async function executeRestore() {
    if (!appState.connected) {
        showNotification('No hay conexión con GitHub', 'error');
        return;
    }
    
    const targetDbUrl = document.getElementById('targetDbUrl').value.trim();
    const backupDate = document.getElementById('backupDate').value;
    const restoreRoles = document.getElementById('restoreRoles').checked;
    const restoreSchema = document.getElementById('restoreSchema').checked;
    const restoreData = document.getElementById('restoreData').checked;
    
    if (!targetDbUrl) {
        showNotification('Por favor ingresa la URL de la base de datos destino', 'error');
        return;
    }
    
    // Confirmación
    if (!confirm('⚠️ ADVERTENCIA: Esta operación modificará la base de datos destino. ¿Estás seguro?')) {
        return;
    }
    
    const restoreWorkflow = appState.workflows.find(w => 
        w.name === 'restaurar-supabase' || w.name === 'supabase-restore'
    );
    
    if (!restoreWorkflow) {
        showNotification('No se encontró el workflow de restauración', 'error');
        return;
    }
    
    try {
        showNotification('Iniciando restauración...', 'info');
        logMessage('Disparando workflow de restauración', 'info');
        
        const response = await githubAPI('POST',
            `/repos/${config.repoOwner}/${config.repoName}/actions/workflows/${restoreWorkflow.id}/dispatches`,
            {
                ref: 'main',
                inputs: {
                    target_db_url: targetDbUrl,
                    backup_date: backupDate,
                    restore_roles: restoreRoles.toString(),
                    restore_schema: restoreSchema.toString(),
                    restore_data: restoreData.toString()
                }
            }
        );
        
        if (response.ok) {
            showNotification('Restauración iniciada correctamente', 'success');
            logMessage(`Restauración iniciada: ${backupDate} -> Base de datos destino`, 'success');
            closeModal('restoreModal');
            
            // Limpiar formulario
            document.getElementById('targetDbUrl').value = '';
            document.getElementById('backupDate').value = 'latest';
            
            setTimeout(refreshHistory, 3000);
        } else {
            throw new Error(`Error ${response.status}: ${response.data.message}`);
        }
    } catch (error) {
        showNotification('Error al iniciar restauración: ' + error.message, 'error');
        logMessage('Error al disparar workflow de restauración: ' + error.message, 'error');
    }
}

// Historial de respaldos
async function refreshHistory() {
    if (!appState.connected) return;
    
    try {
        logMessage('Actualizando historial de respaldos...', 'info');
        
        // Obtener runs de workflows
        const response = await githubAPI('GET', 
            `/repos/${config.repoOwner}/${config.repoName}/actions/runs?per_page=20`
        );
        
        if (response.ok) {
            const runs = response.data.workflow_runs.filter(run => 
                run.name === 'respaldo-supabase' || 
                run.name === 'supabase-backup' ||
                run.name === 'restaurar-supabase' ||
                run.name === 'supabase-restore'
            );
            
            displayBackupHistory(runs);
            updateLastBackupInfo(runs);
            logMessage('Historial actualizado correctamente', 'success');
        }
    } catch (error) {
        logMessage('Error al actualizar historial: ' + error.message, 'error');
    }
}

function displayBackupHistory(runs) {
    const container = document.getElementById('backupList');
    
    if (runs.length === 0) {
        container.innerHTML = `
            <div class="text-center" style="padding: 2rem; color: var(--text-secondary);">
                <i class="fas fa-inbox fa-3x"></i>
                <p style="margin-top: 1rem;">No hay respaldos disponibles</p>
                <p style="font-size: 0.9rem;">Ejecuta tu primer respaldo para verlo aquí</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = runs.map(run => {
        const date = new Date(run.created_at);
        const status = getStatusIcon(run.status, run.conclusion);
        const isBackup = run.name.includes('backup') || run.name.includes('respaldo');
        const type = isBackup ? 'Respaldo' : 'Restauración';
        const typeIcon = isBackup ? 'fas fa-download' : 'fas fa-upload';
        
        return `
            <div class="backup-item">
                <div class="backup-info">
                    <h4>
                        <i class="${typeIcon}"></i>
                        ${type} - ${date.toLocaleDateString('es-ES')} ${date.toLocaleTimeString('es-ES')}
                    </h4>
                    <p>
                        ${status.icon} ${status.text} • 
                        Duración: ${formatDuration(run.created_at, run.updated_at)}
                    </p>
                </div>
                <div class="backup-actions">
                    <button class="btn btn-sm btn-secondary" onclick="viewWorkflowRun('${run.html_url}')">
                        <i class="fas fa-external-link-alt"></i> Ver Detalles
                    </button>
                    ${run.conclusion === 'success' && isBackup ? `
                        <button class="btn btn-sm btn-primary" onclick="useBackupForRestore('${date.toISOString().split('T')[0]}')">
                            <i class="fas fa-upload"></i> Usar para Restaurar
                        </button>
                    ` : ''}
                </div>
            </div>
        `;
    }).join('');
}

function getStatusIcon(status, conclusion) {
    if (status === 'in_progress') {
        return { icon: '<i class="fas fa-spinner fa-spin text-warning"></i>', text: 'En progreso' };
    } else if (conclusion === 'success') {
        return { icon: '<i class="fas fa-check-circle text-success"></i>', text: 'Completado' };
    } else if (conclusion === 'failure') {
        return { icon: '<i class="fas fa-times-circle text-danger"></i>', text: 'Fallido' };
    } else if (conclusion === 'cancelled') {
        return { icon: '<i class="fas fa-stop-circle text-secondary"></i>', text: 'Cancelado' };
    } else {
        return { icon: '<i class="fas fa-clock text-secondary"></i>', text: 'Pendiente' };
    }
}

function formatDuration(start, end) {
    const startTime = new Date(start);
    const endTime = new Date(end);
    const duration = (endTime - startTime) / 1000; // en segundos
    
    if (duration < 60) {
        return `${Math.round(duration)}s`;
    } else {
        return `${Math.round(duration / 60)}m ${Math.round(duration % 60)}s`;
    }
}

function updateLastBackupInfo(runs) {
    const lastBackup = runs.find(run => 
        (run.name === 'respaldo-supabase' || run.name === 'supabase-backup') && 
        run.conclusion === 'success'
    );
    
    const lastBackupElement = document.getElementById('lastBackup');
    if (lastBackup) {
        const date = new Date(lastBackup.created_at);
        lastBackupElement.textContent = `Último respaldo: ${date.toLocaleDateString('es-ES')} ${date.toLocaleTimeString('es-ES')}`;
    } else {
        lastBackupElement.textContent = 'Último respaldo: No disponible';
    }
}

// Modal management
function showRestoreModal() {
    // Cargar fechas de respaldo disponibles
    loadAvailableBackupDates();
    document.getElementById('restoreModal').style.display = 'block';
}

function showAdvancedSettings() {
    document.getElementById('advancedModal').style.display = 'block';
}

function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
}

function loadAvailableBackupDates() {
    const select = document.getElementById('backupDate');
    select.innerHTML = '<option value="latest">Último respaldo (Recomendado)</option>';
    
    // Aquí podrías cargar las fechas específicas de respaldos exitosos
    if (appState.connected) {
        // Agregar fechas basadas en el historial
        const successfulBackups = appState.backups?.filter(b => b.status === 'success') || [];
        successfulBackups.forEach(backup => {
            const date = backup.date;
            select.innerHTML += `<option value="${date}">${date}</option>`;
        });
    }
}

// Utility functions
function showBackupHistory() {
    const section = document.getElementById('historySection');
    section.style.display = section.style.display === 'none' ? 'block' : 'none';
    if (section.style.display === 'block') {
        refreshHistory();
    }
}

function viewWorkflowRun(url) {
    window.open(url, '_blank');
}

function useBackupForRestore(date) {
    document.getElementById('backupDate').value = date;
    showRestoreModal();
}

function saveAdvancedSettings() {
    // Implementar guardar configuraciones avanzadas
    showNotification('Configuración avanzada guardada', 'success');
    closeModal('advancedModal');
}

function clearLogs() {
    document.getElementById('logContainer').innerHTML = '';
    logMessage('Registro de actividad limpiado', 'info');
}

function logMessage(message, type = 'info') {
    const container = document.getElementById('logContainer');
    const timestamp = new Date().toLocaleTimeString('es-ES');
    const entry = document.createElement('div');
    entry.className = `log-entry ${type}`;
    entry.innerHTML = `
        <span class="log-time">[${timestamp}]</span>
        <span class="log-message">${message}</span>
    `;
    
    container.appendChild(entry);
    container.scrollTop = container.scrollHeight;
    
    // Limitar a 100 entradas
    while (container.children.length > 100) {
        container.removeChild(container.firstChild);
    }
}

function showNotification(message, type = 'info') {
    // Crear notificación toast
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <i class="fas fa-${getNotificationIcon(type)}"></i>
            <span>${message}</span>
        </div>
    `;
    
    // Estilos para la notificación
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        z-index: 10000;
        padding: 1rem 1.5rem;
        border-radius: 0.5rem;
        color: white;
        font-weight: 500;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        transform: translateX(400px);
        transition: transform 0.3s ease;
        max-width: 400px;
    `;
    
    // Colores según tipo
    const colors = {
        success: '#10b981',
        error: '#ef4444',
        warning: '#f59e0b',
        info: '#3b82f6'
    };
    
    notification.style.backgroundColor = colors[type] || colors.info;
    
    document.body.appendChild(notification);
    
    // Animar entrada
    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Remover después de 5 segundos
    setTimeout(() => {
        notification.style.transform = 'translateX(400px)';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 5000);
    
    // Permitir cerrar al hacer clic
    notification.addEventListener('click', () => {
        notification.style.transform = 'translateX(400px)';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    });
}

function getNotificationIcon(type) {
    const icons = {
        success: 'check-circle',
        error: 'exclamation-circle',
        warning: 'exclamation-triangle',
        info: 'info-circle'
    };
    return icons[type] || icons.info;
}

function initializeApp() {
    logMessage('Panel de control inicializado', 'success');
    
    // Cerrar modales al hacer clic fuera
    window.addEventListener('click', function(event) {
        const modals = document.querySelectorAll('.modal');
        modals.forEach(modal => {
            if (event.target === modal) {
                modal.style.display = 'none';
            }
        });
    });
    
    // Manejo de formularios
    document.getElementById('restoreForm').addEventListener('submit', function(e) {
        e.preventDefault();
        executeRestore();
    });
}

// Event listeners adicionales
document.addEventListener('keydown', function(e) {
    // Cerrar modales con ESC
    if (e.key === 'Escape') {
        document.querySelectorAll('.modal').forEach(modal => {
            modal.style.display = 'none';
        });
    }
});