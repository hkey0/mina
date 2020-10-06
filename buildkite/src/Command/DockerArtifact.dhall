-- Execute Docker artifact release script according to build scoped DOCKER_DEPLOY_ENV

let Prelude = ../External/Prelude.dhall

let Command = ./Base.dhall
let Size = ./Size.dhall

let Cmd = ../Lib/Cmds.dhall

let DockerLogin = ../Command/DockerLogin/Type.dhall


let defaultArtifactStep = { name = "Artifact", key = "build-artifact" }

let ReleaseSpec = {
  Type = {
    deps : List Command.TaggedKey.Type,
    deploy_env_file : Text,
    service: Text,
    version: Text,
    extra_args: Text,
    step_key: Text
  },
  default = {
    deploy_env_file = "DOCKER_DEPLOY_ENV",
    service = "\\\$CODA_SERVICE",
    version = "\\\$CODA_VERSION",
    extra_args = "--build-arg coda_deb_version=\\\${CODA_DEB_VERSION} --build-arg deb_repo=\\\${CODA_DEB_REPO}",
    step_key = "docker-artifact"
  }
}

let generateStep = \(spec : ReleaseSpec.Type) ->
    -- assume head or first dependency specified by spec represents the primary artifact dependency step
    let artifactUploadScope = Prelude.Optional.default Command.TaggedKey.Type defaultArtifactStep (List/head Command.TaggedKey.Type spec.deps) 

    let commands : List Cmd.Type =
    [
        Cmd.run (
            "if [ ! -f ${spec.deploy_env_file} ]; then " ++
                "buildkite-agent artifact download --step _${artifactUploadScope.name}-${artifactUploadScope.key} ${spec.deploy_env_file} .; " ++
            "fi"
        ),
        Cmd.run "source ${spec.deploy_env_file} && ./scripts/release-docker.sh --service ${spec.service} --version ${spec.version} --extra-args ${spec.extra_args}"
    ]

    in

    Command.build
      Command.Config::{
        commands  = commands,
        label = "Build and release Docker artifacts: ${spec.step_key}",
        key = spec.step_key,
        target = Size.XLarge,
        docker_login = Some DockerLogin::{=},
        depends_on = spec.deps
      }

in

{ generateStep = generateStep, ReleaseSpec = ReleaseSpec }
