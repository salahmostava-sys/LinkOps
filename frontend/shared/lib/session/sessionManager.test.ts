import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { SessionManager } from './sessionManager';
import { SESSION_ACTIVITY_EVENTS } from './sessionConstants';

describe('SessionManager', () => {
  let onWarning: ReturnType<typeof vi.fn>;
  let onTimeout: ReturnType<typeof vi.fn>;
  let onActivityFromOtherTab: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    vi.useFakeTimers();
    onWarning = vi.fn();
    onTimeout = vi.fn();
    onActivityFromOtherTab = vi.fn();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('initializes and starts correctly', () => {
    const manager = new SessionManager({
      inactivityTimeoutMs: 10000,
      warningBeforeMs: 2000,
      onWarning,
      onTimeout,
      onActivityFromOtherTab,
    });

    expect(manager.isRunning).toBe(false);
    manager.start();
    expect(manager.isRunning).toBe(true);
    manager.destroy();
  });

  it('triggers warning and timeout', () => {
    const manager = new SessionManager({
      inactivityTimeoutMs: 10000,
      warningBeforeMs: 2000,
      onWarning,
      onTimeout,
    });

    manager.start();

    // Advance to warning (8000ms)
    vi.advanceTimersByTime(8000);
    expect(onWarning).toHaveBeenCalledTimes(1);
    expect(onTimeout).not.toHaveBeenCalled();

    // Advance to timeout (+2000ms)
    vi.advanceTimersByTime(2000);
    expect(onTimeout).toHaveBeenCalledTimes(1);
    expect(manager.isRunning).toBe(false);

    manager.destroy();
  });

  it('resets timer on local activity', () => {
    const manager = new SessionManager({
      inactivityTimeoutMs: 10000,
      warningBeforeMs: 2000,
      onWarning,
      onTimeout,
    });

    manager.start();

    vi.advanceTimersByTime(5000);
    
    // Simulate user activity event
    document.dispatchEvent(new Event(SESSION_ACTIVITY_EVENTS[0]));

    // Fast forward 5000ms more (total 10000)
    vi.advanceTimersByTime(5000);
    expect(onWarning).not.toHaveBeenCalled(); // timer was reset
    expect(onTimeout).not.toHaveBeenCalled();

    manager.destroy();
  });

  it('stops timers when stop is called', () => {
    const manager = new SessionManager({
      inactivityTimeoutMs: 10000,
      warningBeforeMs: 2000,
      onWarning,
      onTimeout,
    });

    manager.start();
    vi.advanceTimersByTime(5000);
    manager.stop();

    vi.advanceTimersByTime(10000); // would have triggered warning and timeout
    expect(onWarning).not.toHaveBeenCalled();
    expect(onTimeout).not.toHaveBeenCalled();
    expect(manager.isRunning).toBe(false);

    manager.destroy();
  });

  it('handles broadcast events from other tabs', () => {
    let listener: ((ev: MessageEvent) => void) | null = null;
    class BroadcastChannelMock {
      name: string;
      constructor(name: string) {
        this.name = name;
      }
      addEventListener(event: string, cb: any) {
        if (event === 'message') listener = cb;
      }
      removeEventListener() {}
      postMessage() {}
      close() {}
    }

    vi.stubGlobal('BroadcastChannel', BroadcastChannelMock);

    const manager = new SessionManager({
      inactivityTimeoutMs: 10000,
      warningBeforeMs: 2000,
      onWarning,
      onTimeout,
      onActivityFromOtherTab,
    });

    manager.start();

    vi.advanceTimersByTime(5000);

    // Simulate activity from another tab
    if (listener) listener(new MessageEvent('message', { data: { type: 'SESSION_ACTIVITY' } }));

    expect(onActivityFromOtherTab).toHaveBeenCalledTimes(1);

    vi.advanceTimersByTime(8000); // 8 seconds after reset -> warning
    expect(onWarning).toHaveBeenCalledTimes(1);
    expect(onTimeout).not.toHaveBeenCalled();

    // Simulate logout from another tab
    if (listener) listener(new MessageEvent('message', { data: { type: 'SESSION_LOGOUT' } }));
    expect(onTimeout).toHaveBeenCalledTimes(1);
    expect(manager.isRunning).toBe(false);

    manager.destroy();
    vi.unstubAllGlobals();
  });

  it('broadcastLogout works', () => {
    const postMessageMock = vi.fn();
    class BroadcastChannelMock {
      addEventListener() {}
      removeEventListener() {}
      postMessage = postMessageMock;
      close() {}
    }

    vi.stubGlobal('BroadcastChannel', BroadcastChannelMock);

    const manager = new SessionManager({
      onWarning,
      onTimeout,
    });

    manager.start();
    manager.broadcastLogout();

    expect(postMessageMock).toHaveBeenCalledWith({ type: 'SESSION_LOGOUT' });

    manager.destroy();
    vi.unstubAllGlobals();
  });

  it('returns correct remainingMs', () => {
    const manager = new SessionManager({
      inactivityTimeoutMs: 10000,
      warningBeforeMs: 2000,
      onWarning,
      onTimeout,
    });

    expect(manager.remainingMs).toBe(0);

    manager.start();
    expect(manager.remainingMs).toBe(10000);

    vi.advanceTimersByTime(3000);
    expect(manager.remainingMs).toBe(7000);

    manager.destroy();
  });
});
