{
  containers = {
    "invidious-app" = {
      image = "quay.io/invidious/invidious:latest";

      # proxy = {
        # hostname = "invidious.chiliahedron.wtf";
        
      #   public = false;
      #   external = true;
      #   internal = true;
      # };

      volumes = [
        {
          hostPath = "/srv/container/invidious/config.yaml";
          containerPath = "/invidious/config/config.yml";
          volumeType = "file";
          mountOptions = "rw,z";
        }
      ];

      ports = [
        {
          hostPort = "3001";
          containerPort = "3000";
          protocol = "tcp";
        }
      ];

      dependsOn = [
        "invidious-invidious-db"
      ];

      extraOptions = [
        "--health-cmd='wget -nv --tries=1 --spider http://127.0.0.1:3000/api/v1/comments/jNQXAC9IVRw || exit 1'"
        "--health-interval=30s"
        "--health-retries=2"
        "--health-timeout=5s"
      ];
    };
    "invidious-db" = {
      image = "docker.io/library/postgres:14";

      environment = {
        POSTGRES_DB = "invidious";
        POSTGRES_PASSWORD = "kemal";
        POSTGRES_USER = "kemal";
      };

      volumes = [
        {
          hostPath = "/srv/container/invidious/config/sql";
          containerPath = "/config/sql";
          volumeType = "directory";
          mountOptions = "rw";
        }
        {
          hostPath = "/srv/container/invidious/data";
          containerPath = "/var/lib/postgresql/data";
          volumeType = "directory";
          mountOptions = "rw";
        }
        {
          hostPath = "/srv/container/invidious/init-invidious-db.sh";
          containerPath = "/docker-entrypoint-initdb.d/init-invidious-db.sh";
          volumeType = "file";
          mountOptions = "rw,z";
        }
      ];

      extraOptions = [
        "--health-cmd='pg_isready -U $POSTGRES_USER -d $POSTGRES_DB'"
      ];
    };
  };
}