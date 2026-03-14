#!/bin/bash

# Nom de l'hôte à résoudre
HOST="MacBook-pro-de-Rodolphe.local"

resolve_host_ipv4() {
  local host="$1"
  local ip=""

  if command -v avahi-resolve-host-name >/dev/null 2>&1; then
    ip=$(avahi-resolve-host-name "$host" 2>/dev/null | awk '{print $2}' | head -n 1)
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      echo "$ip"
      return 0
    fi
  fi

  if command -v nslookup >/dev/null 2>&1; then
    ip=$(nslookup "$host" 2>/dev/null | awk '/^Address[[:space:]]*[: ]/{print $NF}' | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' | head -n 1)
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      echo "$ip"
      return 0
    fi
  fi

  if command -v ping >/dev/null 2>&1; then
    ip=$(ping -c 1 "$host" 2>/dev/null | sed -nE 's/.*\((([0-9]{1,3}\.){3}[0-9]{1,3})\).*/\1/p' | head -n 1)
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      echo "$ip"
      return 0
    fi
  fi

  return 1
}

# Étape 1 - Récupérer l'adresse IP de l'hôte
IP=$(resolve_host_ipv4 "$HOST")

# Vérifier si l'IP est valide
if [[ -z "$IP" ]]; then
  echo "Erreur : Impossible de résoudre l'IP pour l'hôte $HOST."
  exit 1
fi

echo "Adresse IP récupérée pour $HOST : $IP"

# Étape 2 - Modifier le fichier /etc/hosts
HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.bak"

# Faire une sauvegarde de /etc/hosts
cp "$HOSTS_FILE" "$BACKUP_FILE"

# Supprimer les lignes contenant escapepod.local
sed -i '/[[:space:]]escapepod\.local\([[:space:]]\|$\)/d' "$HOSTS_FILE"

# Ajouter une nouvelle ligne avec escapepod.local et l'adresse IP récupérée
echo -e "$IP escapepod.local" >> "$HOSTS_FILE"

echo "Le fichier /etc/hosts a été mis à jour avec escapepod.local $IP"

# Étape 3 - Enregistrer l'IP dans une variable d'environnement globale
ENV_VAR_NAME="ESCAPEPOD_IP"
PROFILE_FILE="/etc/profile.d/escapepod_env.sh"

# Écriture persistante de la variable d'environnement
printf 'export %s="%s"\n' "$ENV_VAR_NAME" "$IP" > "$PROFILE_FILE"
chmod 0644 "$PROFILE_FILE"

# Activation immédiate dans le shell courant du script
export "${ENV_VAR_NAME}=${IP}"

echo "L'adresse IP a été enregistrée dans la variable d'environnement $ENV_VAR_NAME"
echo "Persistée dans : $PROFILE_FILE"

# Affichage des instructions pour l'utilisateur
echo "Pour accéder à cette variable, utilisez la commande suivante :"
echo "echo \$$ENV_VAR_NAME"

exit 0