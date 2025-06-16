Fuck Docker
It works, but it gaslights you about everything.

Docker is amazing when it works. And when it doesn’t?
It’s a smug little daemon that eats your RAM, forgets your volumes, lies about its health, and restarts things for reasons it refuses to explain.

Scene 1: Everything Is Fine™

You run:
docker ps

It tells you:
azuracast Up 30 seconds
db Up 31 seconds
nginx Up 30 seconds

Everything is up.
Except the site is down.
The UI is dead.
curl gives you nothing.
The logs? Empty.

Docker: “Everything’s running fine 👍”

Scene 2: Logs Are a Lie

docker logs azuracast

Returns:

    Just enough output to give you hope

    Then nothing

    Then silence

You tail it.
You restart it.
You exec into it.
It’s just a tomb with a PID.

Scene 3: It Forgets Everything

You reboot the host.

Suddenly:

    Your containers forget their volumes

    Your docker-compose.override.yml is ignored

    Your networks vanish

    And the bridge interface is now possessed

Scene 4: Volumes Are Haunted

docker volume rm azuracast_station_data

Error: volume is in use

By what?
You stopped all containers. You nuked the services.
It’s still in use — by ghosts.

Eventually you just:

rm -rf /var/lib/docker

Because therapy is cheaper than debugging this.

Scene 5: docker-compose Is a Trick

docker-compose down
docker-compose up -d

Now:

    Some things are gone

    Some things are doubled

    Your stations/ folder is missing

    And your database container is holding a grudge

You try to roll back.
There is no roll back. Only sadness.

Scene 6: It’s Not Even Docker Anymore

Modern Docker is:

    Docker

    Which is actually Moby

    Which uses containerd

    Which is managed by nerdctl

    Which builds with buildkit

    Which logs via journald

    Which stores data in an OCI-conforming mess of layers

None of it can be managed with just docker.

Final Thought

Docker is powerful.
Docker is everywhere.
Docker changed the world.

But once you run real infrastructure on it?

Fuck Docker.
