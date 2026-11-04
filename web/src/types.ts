export type NoticeType = 'success' | 'error' | 'warning' | 'info'
export interface Notice { id: string; title?: string; description: string; type: NoticeType; duration?: number }
export interface MenuItem { title: string; description?: string; icon?: string; disabled?: boolean; metadata?: string[]; menu?: string; value?: unknown }
export interface Field { name: string; label: string; type: 'text' | 'textarea' | 'number' | 'checkbox' | 'select' | 'multiselect' | 'slider' | 'date' | 'color'; required?: boolean; default?: unknown; options?: Array<{ label: string; value: string }> }
export interface NuiMessage<T = unknown> { action: string; data: T }

/** 'compact' renderiza a confirmacao de forma discreta, sem backdrop escurecendo a tela. */
export type AlertVariant = 'modal' | 'compact'

/** Payload aceito por exports.mz_lib:alertDialog(options). */
export interface AlertDialogOptions {
  title?: string
  description?: string
  /** Com true, Y/N/ESC respondem pela NUI sem cursor. */
  keyboard?: boolean
  confirmLabel?: string
  cancelLabel?: string
  /** Tempo em ms antes de fechar sozinho e retornar nil. Sem valor, aguarda o jogador. */
  duration?: number
  variant?: AlertVariant
  /** Adicionado pelo client Lua em cada request. */
  requestId?: string
}
