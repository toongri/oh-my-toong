/**
 * oh-my-toong TypeScript Logging Module
 * Provides structured logging for TypeScript hooks and scripts
 *
 * Mirrors the behavior of hooks/lib/logging.sh
 */
export declare enum LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3
}
/**
 * Initialize logging for a component
 *
 * @param component - Name of the component (used in log messages and filename)
 * @param projectRoot - Project root directory (where .claude/sisyphus/logs will be created)
 * @param sessionId - Optional session ID (defaults to 'default')
 */
export declare function initLogger(component: string, projectRoot: string, sessionId?: string): void;
/**
 * Log at DEBUG level
 */
export declare function logDebug(message: string): void;
/**
 * Log at INFO level
 */
export declare function logInfo(message: string): void;
/**
 * Log at WARN level
 */
export declare function logWarn(message: string): void;
/**
 * Log at ERROR level
 */
export declare function logError(message: string): void;
/**
 * Log start marker
 */
export declare function logStart(): void;
/**
 * Log end marker
 */
export declare function logEnd(): void;
