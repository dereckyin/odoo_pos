import 'package:pos_core/pos_core.dart';
import '../entities/member.dart';
import '../entities/coupon.dart';

abstract interface class MemberRepository {
  Future<Result<Member?>> findByPhone(String phone);
  Future<Result<Member?>> findByQr(String qr);
  Future<Result<Member?>> findById(String id);
  Future<Result<List<Member>>> search(String query, {int limit = 30});

  Future<Result<Member>> upsert(Member member);
  Future<Result<int>> applyServerDelta(List<Member> members);

  Future<Result<List<MemberLevel>>> levels();
  Future<Result<List<Coupon>>> couponsFor(String memberId);
  Future<Result<PointTransaction>> recordPoints(PointTransaction tx);
}
