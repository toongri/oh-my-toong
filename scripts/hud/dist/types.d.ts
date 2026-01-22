export interface StdinInput {
    hook_event_name: string;
    session_id: string;
    transcript_path: string;
    cwd: string;
    workspace?: {
        project_dir: string;
    };
    context_window: {
        used_percentage: number;
        total_input_tokens: number;
        context_window_size: number;
    };
}
export interface RalphState {
    active: boolean;
    iteration: number;
    max_iterations: number;
    completion_promise: string;
    prompt: string;
    started_at: string;
    linked_ultrawork: boolean;
}
export interface UltraworkState {
    active: boolean;
    started_at: string;
    original_prompt: string;
    reinforcement_count: number;
    last_checked_at?: string;
    linked_to_ralph: boolean;
}
export interface RalphVerification {
    pending: boolean;
    verification_attempts: number;
    max_verification_attempts: number;
    original_task: string;
    completion_claim: string;
    oracle_feedback?: string;
    created_at: string;
}
export interface TodoItem {
    content: string;
    status: 'pending' | 'in_progress' | 'completed';
    activeForm?: string;
}
export interface TodosState {
    todos: TodoItem[];
}
export interface HudData {
    contextPercent: number | null;
    ralph: RalphState | null;
    ultrawork: UltraworkState | null;
    ralphVerification: RalphVerification | null;
    todos: {
        completed: number;
        total: number;
    } | null;
    runningAgents: number;
    backgroundTasks: number;
    activeSkill: string | null;
}
export interface TranscriptData {
    runningAgents: number;
    activeSkill: string | null;
}
export declare const ANSI: {
    readonly reset: "\u001B[0m";
    readonly green: "\u001B[32m";
    readonly yellow: "\u001B[33m";
    readonly red: "\u001B[31m";
    readonly bold: "\u001B[1m";
};
