import client from './client'
import type {
  MemberOverview, LevelStat, RfmCell, CohortRow, ChurnMember,
} from '@/types'

export function getMemberOverview() {
  return client.get<MemberOverview>('/analytics/members/overview')
}

export function getMemberLevelStats() {
  return client.get<LevelStat[]>('/analytics/members/levels')
}

export function getMemberRfm() {
  return client.get<RfmCell[]>('/analytics/members/rfm')
}

export function getMemberCohort() {
  return client.get<CohortRow[]>('/analytics/members/cohort')
}

export function getChurnRisk(limit = 50) {
  return client.get<ChurnMember[]>('/analytics/members/churn-risk', { params: { limit } })
}
