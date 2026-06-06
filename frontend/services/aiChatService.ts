import { supabase } from '@services/supabase/client';
import { toServiceError } from '@services/serviceError';

export interface AiChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

type AiChatResponse = {
  message?: string;
  error?: string;
};

async function getAuthHeader(): Promise<string | null> {
  const { data } = await supabase.auth.getSession();
  const token = data.session?.access_token;
  return token ? `Bearer ${token}` : null;
}

export const aiChatService = {
  sendMessage: async (messages: AiChatMessage[]): Promise<string> => {
    const authHeader = await getAuthHeader();
    if (!authHeader) {
      throw toServiceError(new Error('Not authenticated'), 'aiChatService.sendMessage');
    }

    const { data, error } = await supabase.functions.invoke('ai-chat', {
      body: { messages },
    });

    if (error) {
      const msg = error.message ?? 'عذرًا، حدث خطأ في الاتصال. حاول مرة أخرى.';
      throw toServiceError(new Error(msg), 'aiChatService.sendMessage');
    }

    const aiData = data as AiChatResponse;
    return aiData?.message ?? aiData?.error ?? 'لا يوجد رد';
  },
};
