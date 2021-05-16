import Combine
import Foundation
import HealthKit

public struct Workout {
  public private(set) var healthStore: HKHealthStore

  public init(healthStore: HKHealthStore) {
    self.healthStore = healthStore
  }

  public func workouts(
    activityType: HKWorkoutActivityType,
    startDate: Date,
    endDate: Date
  ) -> Future<[HKWorkout], Error> {
    Future { completion in
      let workoutPredicate = HKQuery.predicateForWorkouts(with: activityType)
      let samplePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
      let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [workoutPredicate, samplePredicate])
      let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
      let query = HKSampleQuery(
        sampleType: .workoutType(),
        predicate: compoundPredicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [sortDescriptor]
      ) { query, samples, error in
        guard let workouts = samples as? [HKWorkout], error == nil else { completion(.failure(error!)); return }
        completion(.success(workouts))
      }
      healthStore.execute(query)
    }
  }

  #if os(watchOS)
  public func session(
    activityType: HKWorkoutActivityType,
    locationType: HKWorkoutSessionLocationType
  ) -> Future<HKWorkoutSession, Error> {
    Future { completion in
      let configuration = HKWorkoutConfiguration()
      configuration.activityType = activityType
      configuration.locationType = locationType
      do {
        let session = try HKWorkoutSession(
          healthStore: healthStore,
          configuration: configuration
        )
        completion(.success(session))
      } catch {
        completion(.failure(error))
      }
    }
  }
  #endif
}
