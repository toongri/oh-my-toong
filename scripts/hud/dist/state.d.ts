import type { RalphState, UltraworkState, RalphVerification } from './types.js';
export declare function readRalphState(cwd: string): Promise<RalphState | null>;
export declare function readUltraworkState(cwd: string): Promise<UltraworkState | null>;
export declare function readRalphVerification(cwd: string): Promise<RalphVerification | null>;
export declare function readTodos(cwd: string): Promise<{
    completed: number;
    total: number;
} | null>;
export declare function readBackgroundTasks(): Promise<number>;
