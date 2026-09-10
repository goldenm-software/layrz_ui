import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  final fixedNow = DateTime(2026, 1, 1, 12, 0, 0);

  group('resolveLayrzConnectionState', () {
    test('null receivedAt always resolves to noData, regardless of times', () {
      expect(
        resolveLayrzConnectionState(receivedAt: null, now: fixedNow),
        LayrzConnectionState.noData,
      );
    });

    test('0 elapsed resolves to online', () {
      final state = resolveLayrzConnectionState(receivedAt: fixedNow, now: fixedNow);
      expect(state, LayrzConnectionState.online);
    });

    test('10 minutes elapsed (within default 15-minute online threshold) resolves to online', () {
      final receivedAt = fixedNow.subtract(const Duration(minutes: 10));
      final state = resolveLayrzConnectionState(receivedAt: receivedAt, now: fixedNow);
      expect(state, LayrzConnectionState.online);
    });

    test('exactly the online boundary (15 minutes) still resolves to online (inclusive)', () {
      final receivedAt = fixedNow.subtract(const Duration(minutes: 15));
      final state = resolveLayrzConnectionState(receivedAt: receivedAt, now: fixedNow);
      expect(state, LayrzConnectionState.online);
    });

    test('20 minutes elapsed (past online, within default 60-minute idle threshold) resolves to idle', () {
      final receivedAt = fixedNow.subtract(const Duration(minutes: 20));
      final state = resolveLayrzConnectionState(receivedAt: receivedAt, now: fixedNow);
      expect(state, LayrzConnectionState.idle);
    });

    test('90 minutes elapsed (past idle, within 30 days) resolves to offline', () {
      final receivedAt = fixedNow.subtract(const Duration(minutes: 90));
      final state = resolveLayrzConnectionState(receivedAt: receivedAt, now: fixedNow);
      expect(state, LayrzConnectionState.offline);
    });

    test('exactly the offline boundary (30 days) still resolves to offline (inclusive)', () {
      final receivedAt = fixedNow.subtract(const Duration(days: 30));
      final state = resolveLayrzConnectionState(receivedAt: receivedAt, now: fixedNow);
      expect(state, LayrzConnectionState.offline);
    });

    test('40 days elapsed (past the 30-day boundary) resolves to disconnected', () {
      final receivedAt = fixedNow.subtract(const Duration(days: 40));
      final state = resolveLayrzConnectionState(receivedAt: receivedAt, now: fixedNow);
      expect(state, LayrzConnectionState.disconnected);
    });

    test('a receivedAt in the future is treated as zero elapsed (online), not a negative offset', () {
      final receivedAt = fixedNow.add(const Duration(minutes: 5));
      final state = resolveLayrzConnectionState(receivedAt: receivedAt, now: fixedNow);
      expect(state, LayrzConnectionState.online);
    });

    test('custom LayrzConnectionTimes thresholds are honored over the defaults', () {
      const customTimes = LayrzConnectionTimes(online: Duration(minutes: 5), idle: Duration(minutes: 10));
      final receivedAt = fixedNow.subtract(const Duration(minutes: 7));

      // 7 minutes would be "online" under the 15-minute default, but must
      // resolve to "idle" under this 5-minute custom threshold.
      final state = resolveLayrzConnectionState(receivedAt: receivedAt, now: fixedNow, times: customTimes);
      expect(state, LayrzConnectionState.idle);
    });
  });

  group('LayrzConnectionState.colorOf', () {
    final tokens = LayrzTokens.light();

    test('online resolves to the success token', () {
      expect(LayrzConnectionState.online.colorOf(tokens), tokens.colors.success);
    });

    test('idle resolves to the warning token', () {
      expect(LayrzConnectionState.idle.colorOf(tokens), tokens.colors.warning);
    });

    test('offline resolves to the danger token', () {
      expect(LayrzConnectionState.offline.colorOf(tokens), tokens.colors.danger);
    });

    test('disconnected resolves to the fg1 foreground token (not a semantic swatch)', () {
      expect(LayrzConnectionState.disconnected.colorOf(tokens), tokens.colors.fg1);
    });

    test('noData resolves to the contextual token', () {
      expect(LayrzConnectionState.noData.colorOf(tokens), tokens.colors.contextual);
    });
  });
}
