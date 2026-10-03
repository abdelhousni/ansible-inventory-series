# shellcheck shell=bash
# Sourced by the run.sh of examples that start target hosts. Picks the
# container runtime from LAB_RUNTIME (docker, podman or kubernetes), or the
# first one available, and gives the same few verbs for each:
#   lab_build TAG CONTAINERFILE CONTEXT
#   lab_run NAME IMAGE HOSTNAME [PORT] [COMMAND...]   PORT publishes 127.0.0.1:PORT
#   lab_exec NAME COMMAND...      lab_cp FILE NAME:PATH      lab_rm NAME...
# and LAB_INVENTORY, the inventory overlay that sets each host's connection
# for that runtime (empty for docker, the examples' default).

if [ -z "${LAB_RUNTIME:-}" ]; then
  if command -v docker >/dev/null && docker info >/dev/null 2>&1; then LAB_RUNTIME=docker
  elif command -v podman >/dev/null && podman info >/dev/null 2>&1; then LAB_RUNTIME=podman
  else echo "No container runtime: install Docker or Podman, or set LAB_RUNTIME" >&2; exit 1
  fi
fi

case "$LAB_RUNTIME" in
  docker | podman)
    lab_build() { "$LAB_RUNTIME" build -q -t "$1" -f "$2" "$3" >/dev/null; }
    lab_run() {
      local name=$1 image=$2 hostname=$3 port=${4:-}
      shift 4 2>/dev/null || shift $#
      "$LAB_RUNTIME" run -d --name "$name" --hostname "$hostname" \
        ${port:+-p "127.0.0.1:$port:$port"} "$image" "$@" >/dev/null
    }
    lab_exec() { "$LAB_RUNTIME" exec "$@"; }
    lab_cp() { "$LAB_RUNTIME" cp "$1" "$2"; }
    lab_rm() { "$LAB_RUNTIME" rm -f "$@" >/dev/null 2>&1 || true; }
    ;;
  kubernetes)
    # A kind cluster named "lab": images are built with Docker and loaded
    # into it; pods use them without pulling.
    LAB_KIND_CLUSTER=${LAB_KIND_CLUSTER:-lab}
    lab_build() {
      docker build -q -t "$1" -f "$2" "$3" >/dev/null
      kind load docker-image "$1" --name "$LAB_KIND_CLUSTER" >/dev/null 2>&1
    }
    lab_run() {
      local name=$1 image=$2 hostname=$3 port=${4:-}
      shift 4 2>/dev/null || shift $#
      local cmd=""
      [ $# -gt 0 ] && cmd=$(printf ',"command":["%s"' "$1"; shift; for a in "$@"; do printf ',"%s"' "$a"; done; printf ']')
      kubectl run "$name" --image="$image" --image-pull-policy=Never --restart=Never \
        --overrides="{\"spec\":{\"hostname\":\"$hostname\",\"containers\":[{\"name\":\"$name\",\"image\":\"$image\",\"imagePullPolicy\":\"Never\"$cmd}]}}" >/dev/null
      kubectl wait --for=condition=Ready "pod/$name" --timeout=120s >/dev/null
      if [ -n "$port" ]; then
        kubectl port-forward "pod/$name" "$port:$port" >/dev/null 2>&1 &
        echo $! >"out/port-forward-$name.pid"
      fi
    }
    lab_exec() { local name=$1; shift; kubectl exec "$name" -- "$@"; }
    lab_cp() { kubectl cp "$1" "${2%%:*}:${2#*:}" >/dev/null; }
    lab_rm() {
      local name
      for name in "$@"; do
        [ -f "out/port-forward-$name.pid" ] && kill "$(cat "out/port-forward-$name.pid")" 2>/dev/null
        kubectl delete pod "$name" --now --ignore-not-found >/dev/null 2>&1 || true
      done
    }
    ;;
  *)
    echo "LAB_RUNTIME must be docker, podman or kubernetes, not $LAB_RUNTIME" >&2
    exit 1
    ;;
esac

LAB_INVENTORY=""
if [ "$LAB_RUNTIME" != docker ] && [ -d "runtimes/$LAB_RUNTIME" ]; then
  LAB_INVENTORY="runtimes/$LAB_RUNTIME"
fi
export LAB_RUNTIME LAB_INVENTORY
