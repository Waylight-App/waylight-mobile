# R8 rules of the release build (#174).

# WorkManager (refresh of the home screen widgets, ADR 0009) creates its Room
# database and the workers by reflection when the app starts; without these
# rules R8 removes the constructors and the app crashes at launch.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}
