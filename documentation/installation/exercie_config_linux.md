Voici une procédure détaillée de test et de paramétrage du système d’exploitation Ubuntu pour MongoDB, couvrant les aspects NTP, sysctl, swap, et autres optimisations critiques.

## ✅ Paramétrage du Système d’Exploitation pour MongoDB

### 1. **Synchronisation du Temps (NTP)**

**Objectif** : Assurer la cohérence temporelle entre les nœuds MongoDB[1][2].

- **Vérification de la présence de NTP** :
  ```bash
  systemctl status ntp
  ```
  ou pour chrony (alternatif moderne sur Ubuntu) :
  ```bash
  systemctl status chrony
  ```
- **Installation** (si non installé) :
  ```bash
  sudo apt-get install ntp
  ```
- **Vérification du bon fonctionnement** :
  ```bash
  ntpq -p
  ```
  - **Interprétation** : Cherchez une ligne avec `*` devant l’adresse IP, signifiant que le serveur est synchronisé[3][4].
- **Remédiation** : Si le service n’est pas actif ou non synchronisé, relancez-le :
  ```bash
  sudo systemctl restart ntp
  ```

### 2. **Optimisation des Paramètres Kernel (sysctl)**

**Objectif** : Améliorer la performance réseau et la gestion de la mémoire[1][5][2].

- **Vérification des paramètres actuels** :
  ```bash
  sysctl net.core.somaxconn
  sysctl net.ipv4.tcp_max_syn_backlog
  sysctl vm.swappiness
  ```
- **Paramétrage recommandé** (ajoutez à `/etc/sysctl.d/mongodb-sysctl.conf`) :
  ```plaintext
  net.core.somaxconn = 4096
  net.ipv4.tcp_fin_timeout = 30
  net.ipv4.tcp_keepalive_intvl = 30
  net.ipv4.tcp_keepalive_time = 120
  net.ipv4.tcp_max_syn_backlog = 4096
  vm.swappiness = 1
  ```
- **Application des changements** :
  ```bash
  sudo sysctl -p /etc/sysctl.d/mongodb-sysctl.conf
  ```
- **Remédiation** : Si le fichier n’existe pas, créez-le et appliquez les modifications.

### 3. **Configuration du Swap**

**Objectif** : Limiter l’utilisation du swap pour privilégier la RAM, ce qui améliore les performances MongoDB[1][5][2].

- **Vérification de la taille du swap** :
  ```bash
  free -m
  sudo swapon --show
  ```
- **Vérification de la valeur de swappiness** :
  ```bash
  cat /proc/sys/vm/swappiness
  ```
- **Paramétrage recommandé** :
  - Ajoutez ou modifiez dans `/etc/sysctl.conf` :
    ```plaintext
    vm.swappiness = 1
    ```
  - Appliquez :
    ```bash
    sudo sysctl -p
    ```
- **Ajout ou ajustement du swap** (si nécessaire) :
  ```bash
  # Création d’un fichier swap (exemple 8GB)
  sudo fallocate -l 8G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  # Rendre le swap permanent
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  ```
- **Remédiation** : Si le swap est trop utilisé, ajustez la valeur de swappiness et/ou augmentez la RAM disponible[6][7].

### 4. **Autres Optimisations Recommandées**

- **Limites de fichiers et processus** :
  - Modifiez `/etc/security/limits.conf` :
    ```plaintext
    mongod soft nofile 64000
    mongod hard nofile 64000
    mongod soft nproc 64000
    mongod hard nproc 64000
    ```
  - Appliquez les changements et redémarrez le service MongoDB[8].
- **Désactivation des Transparent Huge Pages (THP)** :
  - Vérification :
    ```bash
    cat /proc/sys/vm/nr_hugepages
    ```
  - Si non désactivé, suivez la documentation MongoDB pour le désactiver[2].
- **Sélection du scheduler disque** :
  - Vérification :
    ```bash
    cat /sys/block/sda/queue/scheduler
    ```
  - Recommandé : `deadline` ou `noop` pour les systèmes SSD[5].

## 📊 Tableau Récapitulatif

| Paramètre         | Vérification                        | Paramétrage recommandé                | Remédiation/Application                  |
|-------------------|-------------------------------------|---------------------------------------|------------------------------------------|
| NTP               | `ntpq -p`                           | Installer ntp, vérifier la synchro    | `sudo systemctl restart ntp`             |
| Kernel (sysctl)   | `sysctl net.core.somaxconn`         | Ajouter dans `/etc/sysctl.d/`         | `sudo sysctl -p`                         |
| Swap              | `cat /proc/sys/vm/swappiness`       | `vm.swappiness = 1`                   | Ajouter swap, ajuster swappiness         |
| Limites           | `ulimit -n`                         | Modifier `/etc/security/limits.conf`  | Redémarrer MongoDB                       |
| THP               | `cat /proc/sys/vm/nr_hugepages`     | Désactiver THP                        | Suivre doc MongoDB                       |
| Scheduler disque  | `cat /sys/block/sda/queue/scheduler`| `deadline` ou `noop`                  | Modifier via udev                        |

## ⚠️ Points de vigilance

- **Sécurité** : Ne jamais laisser le swap sans restriction d’accès. Protégez les fichiers sensibles.
- **Performance** : Un swap trop utilisé dégrade les performances. Privilégiez la RAM.
- **Compatibilité** : Vérifiez que tous les paramètres sont compatibles avec votre version d’Ubuntu et MongoDB.
- **Continuité de service** : Appliquez les changements de façon permanente et testez-les en environnement de pré-production.

Cette procédure couvre l’ensemble des paramétrages système essentiels pour une installation MongoDB optimale et robuste sur Ubuntu.

[1] https://severalnines.com/blog/optimizing-your-linux-environment-mongodb/
[2] https://severalnines.com/blog/performance-cheat-sheet-mongodb/
[3] https://hostman.com/tutorials/setting-up-ntp-on-a-server/
[4] https://superuser.com/questions/181341/how-to-check-if-ntp-adjusted-system-time-on-linux
[5] https://www.percona.com/blog/tuning-linux-for-mongodb/
[6] https://dev.to/lovestaco/how-to-add-swap-space-on-linux-e28
[7] https://www.redhat.com/en/blog/clear-swap-linux
[8] https://infohub.delltechnologies.com/l/dell-powerstore-mongodb-solution-guide/operating-system-tuning-2/
[9] https://www.percona.com/blog/tuning-linux-for-mongodb-automated-tuning-redhat-and-centos/
[10] https://www.mongodb.com/docs/manual/administration/production-notes/
[11] https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2023-MongoDB-on-Nutanix%3Abest-practices-for-running-mongodb-on-linux.html
[12] https://docs.redhat.com/fr/documentation/red_hat_enterprise_linux/7/html/system_administrators_guide/s1-checking_the_status_of_ntp
[13] https://docs.redhat.com/fr/documentation/red_hat_enterprise_linux/7/html/system_administrators_guide/s1-configure_ntp
[14] https://serverfault.com/questions/1114985/how-to-verify-the-setting-of-linux-ntp-client
[15] https://docs.ntpsec.org/latest/ntp_conf.html
[16] https://dzone.com/articles/tuning-linux-for-mongodb
[17] https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-ubuntu-20-04
[18] https://www.veritas.com/support/en_US/doc/132509853-165959817-0/v139668337-165959817
[19] https://amperecomputing.com/tuning-guides/mongoDB-tuning-guide