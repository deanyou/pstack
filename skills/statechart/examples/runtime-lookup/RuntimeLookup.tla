---- MODULE RuntimeLookup ----
VARIABLES input, phase, jarSource, javaSource, downloaded
vars == <<input, phase, jarSource, javaSource, downloaded>>

Init ==
    /\ input \in [envJar: BOOLEAN, envJava: BOOLEAN,
                   config: {"absent", "valid", "invalid"},
                   miseReady: BOOLEAN, installOK: BOOLEAN]
    /\ phase = "start"
    /\ jarSource = "none"
    /\ javaSource = "none"
    /\ downloaded = FALSE

Select(jar, java) ==
    /\ phase' = "ready"
    /\ jarSource' = jar
    /\ javaSource' = java

UseEnvironment ==
    /\ phase = "start" /\ input.envJar
    /\ Select("environment", IF input.envJava THEN "environment" ELSE "path")
    /\ UNCHANGED <<input, downloaded>>

CheckLocal ==
    /\ phase = "start" /\ ~input.envJar
    /\ phase' = "local"
    /\ UNCHANGED <<input, jarSource, javaSource, downloaded>>

UseLocal ==
    /\ phase = "local" /\ input.config = "valid"
    /\ Select("local", IF input.envJava THEN "environment" ELSE "local")
    /\ UNCHANGED <<input, downloaded>>

RejectLocal ==
    /\ phase = "local" /\ input.config = "invalid"
    /\ phase' = "error"
    /\ UNCHANGED <<input, jarSource, javaSource, downloaded>>

CheckMise ==
    /\ phase = "local" /\ input.config = "absent"
    /\ phase' = "mise"
    /\ UNCHANGED <<input, jarSource, javaSource, downloaded>>

UseMise ==
    /\ phase = "mise" /\ input.miseReady
    /\ Select("mise", IF input.envJava THEN "environment" ELSE "mise")
    /\ UNCHANGED <<input, downloaded>>

StartInstall ==
    /\ phase = "mise" /\ ~input.miseReady
    /\ phase' = "install"
    /\ downloaded' = TRUE
    /\ UNCHANGED <<input, jarSource, javaSource>>

InstallSucceeds ==
    /\ phase = "install" /\ input.installOK
    /\ Select("mise", IF input.envJava THEN "environment" ELSE "mise")
    /\ UNCHANGED <<input, downloaded>>

InstallFails ==
    /\ phase = "install" /\ ~input.installOK
    /\ phase' = "error"
    /\ UNCHANGED <<input, jarSource, javaSource, downloaded>>

Done == phase \in {"ready", "error"} /\ UNCHANGED vars

Next == UseEnvironment \/ CheckLocal \/ UseLocal \/ RejectLocal \/ CheckMise
        \/ UseMise \/ StartInstall \/ InstallSucceeds \/ InstallFails \/ Done

EnvironmentFirst ==
    (phase = "ready" /\ input.envJar) => jarSource = "environment"

LocalBeforeMise ==
    (phase = "ready" /\ ~input.envJar /\ input.config = "valid") =>
        jarSource = "local"

JavaOverride ==
    (phase = "ready" /\ input.envJava) => javaSource = "environment"

DefaultJava ==
    (phase = "ready" /\ ~input.envJava) =>
        javaSource = (IF jarSource = "environment" THEN "path" ELSE jarSource)

NoUnnecessaryInstall ==
    downloaded => (~input.envJar /\ input.config = "absent" /\ ~input.miseReady)

InvalidConfigStops ==
    (~input.envJar /\ input.config = "invalid") =>
        (phase # "ready" /\ ~downloaded)

CompleteSelection ==
    (phase = "ready") => (jarSource # "none" /\ javaSource # "none")
====
