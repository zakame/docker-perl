local official_images_repo = 'https://github.com/docker-library/official-images.git';

local BuildAndTestImagesPipeline(version, variant, osversion = 'buster') = {
  kind: "pipeline",
  type: "docker",
  name: "build-and-test-" + version + '-' + variant + '-' + osversion,
  steps: [
    {
      name: "build-image",
      image: "docker:dind",
      volumes: [
        {
          name: "dockersock",
          path: "/var/run"
        }
      ],
      commands: [
        "sleep 10",
        "docker version",
        "docker build --no-cache --tag perl " + version + '-' + variant + '-' + osversion
      ]
    },
    {
      name: "test-image",
      image:  "docker:dind",
      volumes: [
        {
          name: "dockersock",
          path: "/var/run"
        }
      ],
      commands: [
        "apk add --no-cache bash git",
        "git clone --depth 1 --single-branch " + official_images_repo,
        "./official-images/test/run.sh perl"
      ]
    }
  ],
  services: [
    {
      name: "docker",
      image: "docker:dind",
      privileged: true,
      volumes: [
        {
          name: "dockersock",
          path: "/var/run"
        }
      ]
    }
  ],
  volumes: [
    {
      name: "dockersock",
      temp: { }
    }
  ]
};

local GeneratePatchesPipeline() = {
  kind: "pipeline",
  type: "docker",
  name: "generate",
  steps: [
    {
      name: "generate-dockerfiles-patches",
      image: "buildpack-deps:buster",
      commands: [
        "git config --global user.email 'test@drone'",
        "git config --global user.name 'Drone CI'",
        "apt-get update",
        "apt-get install --no-install-recommends -y perl cpanminus libwww-perl",
        "cpanm --quiet --installdeps --notest --local-lib-contained local .",
        "perl -Ilocal/lib/perl5 ./generate.pl"
      ]
    }
  ]
};

[
  GeneratePatchesPipeline()
] + [
  BuildAndTestImagesPipeline(version, variant)
  for version in ["5.032.000", "5.030.003"]
  for variant in ["main", "main,threaded", "slim", "slim,threaded"]
]

