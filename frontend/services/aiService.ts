/**
 * AI Service - Analytics and Analysis Functions Only
 * Chat functionality has been removed
 */

export interface BestEmployeeResponse {
  employees: Array<{
    id: string;
    name: string;
    score: number;
    reason: string;
  }>;
}

export interface SalaryForecastResponse {
  predicted_salary: number;
  confidence: 'high' | 'medium' | 'low';
  trend: 'up' | 'down' | 'stable';
  avg_orders_per_day: number;
}

export interface SalaryAnalysisResponse {
  analysis: string;
  recommendations: string[];
  score: number;
  category: 'excellent' | 'good' | 'average' | 'needs_improvement';
}

class AIService {
  private isConfiguredValue = false;

  constructor() {
    // Check if AI backend is configured
    this.isConfiguredValue = this.checkConfiguration();
  }

  private checkConfiguration(): boolean {
    // Check if AI backend URL is configured
    const aiBackendUrl = import.meta.env.VITE_AI_BACKEND_URL;
    return Boolean(aiBackendUrl && aiBackendUrl !== 'none');
  }

  isConfigured(): boolean {
    return this.isConfiguredValue;
  }

  async predictSalary(params: {
    current_orders: number;
    days_passed: number;
    avg_order_value: number;
  }): Promise<SalaryForecastResponse> {
    if (!this.isConfiguredValue) {
      throw new Error('AI backend is not configured');
    }

    const aiBackendUrl = import.meta.env.VITE_AI_BACKEND_URL;
    if (!aiBackendUrl) {
      throw new Error('AI backend URL is not configured');
    }

    try {
      const response = await fetch(`${aiBackendUrl}/predict-salary`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(params),
      });

      if (!response.ok) {
        throw new Error(`AI service error: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('[AIService] predictSalary failed:', error);
      throw error;
    }
  }

  async bestEmployees(
    employees: Array<{ id: string; name: string; performance_score?: number }>,
    limit: number
  ): Promise<BestEmployeeResponse> {
    if (!this.isConfiguredValue) {
      throw new Error('AI backend is not configured');
    }

    const aiBackendUrl = import.meta.env.VITE_AI_BACKEND_URL;
    if (!aiBackendUrl) {
      throw new Error('AI backend URL is not configured');
    }

    try {
      const response = await fetch(`${aiBackendUrl}/best-employees`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ employees, limit }),
      });

      if (!response.ok) {
        throw new Error(`AI service error: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('[AIService] bestEmployees failed:', error);
      throw error;
    }
  }

  async analyzeSalary(
    totalPlatformSalary: number,
    totalOrders: number,
    totalBonus: number
  ): Promise<SalaryAnalysisResponse> {
    if (!this.isConfiguredValue) {
      throw new Error('AI backend is not configured');
    }

    const aiBackendUrl = import.meta.env.VITE_AI_BACKEND_URL;
    if (!aiBackendUrl) {
      throw new Error('AI backend URL is not configured');
    }

    try {
      const response = await fetch(`${aiBackendUrl}/analyze-salary`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          totalPlatformSalary,
          totalOrders,
          totalBonus,
        }),
      });

      if (!response.ok) {
        throw new Error(`AI service error: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('[AIService] analyzeSalary failed:', error);
      throw error;
    }
  }
}

export const aiService = new AIService();
