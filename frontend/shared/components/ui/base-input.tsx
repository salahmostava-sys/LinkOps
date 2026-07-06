import React from 'react';
import { Input } from './input';
import { Label } from './label';

export interface BaseInputProps extends React.ComponentProps<"input"> {
  label: string;
  error?: string;
  containerClassName?: string;
}

export const BaseInput = React.forwardRef<HTMLInputElement, BaseInputProps>(
  ({ label, error, className = '', containerClassName = '', id, ...props }, ref) => {
    // Generate a stable ID if none is provided to link label and input for accessibility
    const generatedId = React.useId();
    const inputId = id || generatedId;

    return (
      <div className={`space-y-2 ${containerClassName}`}>
        <Label htmlFor={inputId} className={`text-sm font-medium ${error ? 'text-destructive' : 'text-foreground'}`}>
          {label}
        </Label>
        <Input
          id={inputId}
          ref={ref}
          className={`${error ? 'border-destructive focus-visible:ring-destructive/20' : ''} ${className}`}
          aria-invalid={!!error}
          aria-errormessage={error ? `${inputId}-error` : undefined}
          {...props}
        />
        {error && (
          <p id={`${inputId}-error`} className="text-[13px] text-destructive animate-in slide-in-from-top-1">
            {error}
          </p>
        )}
      </div>
    );
  }
);

BaseInput.displayName = 'BaseInput';
