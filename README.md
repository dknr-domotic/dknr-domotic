# README

[![Release](https://img.shields.io/docker/v/jcpd/dknr-domotic?sort=semver)](https://img.shields.io/docker/v/jcpd/dknr-domotic?sort=semver)
[![Pull](https://img.shields.io/docker/pulls/jcpd/dknr-domotic)](https://img.shields.io/docker/pulls/jcpd/dknr-domotic)
[![Issue](https://img.shields.io/github/issues/dknr-domotic/dknr-domotic)](https://img.shields.io/github/issues/dknr-domotic/dknr-domotic)
[![License](https://img.shields.io/github/license/dknr-domotic/dknr-domotic)](https://github.com/dknr-domotic/dknr-domotic/blob/master/LICENSE)


## A propos

**dknr-domotic** est le tableau de bord et le cerveau des projets DKNR. Il réunit dans une même interface toutes les entités publiées sur MQTT par les autres projets DKNR (Zigbee, Z-Wave, RFXCom, Teleinfo, Nuki, Daikin, Zendure, APSystems...), les range par pièce, historise leurs valeurs et les pilote par des scènes, le tout en local.

La documentation détaillée est sur [dknr-domotic.github.io](https://dknr-domotic.github.io/domotic/).


## Fonctionnalités

- **Toutes les sources DKNR** : chaque source se déclare par la discovery DKNR, ses appareils (parents) et ses entités sont créés automatiquement à la première publication.
- **Accueil** : plan de la maison avec la température et l'humidité de chaque pièce, météo (OpenWeatherMap) et prochains événements du calendrier.
- **Pièces** : entités de chaque pièce classées par usage (lumières, volets, ouvertures, températures...), pilotage direct, historique de chaque valeur et caméras.
- **Energie** : carte des flux (réseau, solaire, batterie, maison, lumières), graphiques de puissance, d'énergie et de batterie, tarif en cours.
- **Scènes** : automatismes déclenchés par les entités (voir plus bas), avec le détail du dernier passage de chaque scène pour comprendre ce qu'elle a fait ou pourquoi elle s'est arrêtée.
- **Calendrier** : anniversaires et événements, affichés sur l'accueil.
- **Entités** : nom, pièce, élément, groupe et unité de chaque entité, par source.
- **Modes de la maison** (source interne `dknr`) : automatisme général, jour / nuit, lumières, volets, chauffe-eau, chauffage, ventilation, son, en automatique, forcés ou manuels.
- **Utilisateurs** avec niveau d'accès et langue (français, anglais), session conservée au rafraîchissement de la page et au redémarrage (durée réglable : 6 h, 24 h ou 30 jours), liste des comptes pour déconnecter ou supprimer un utilisateur (administrateur et parent).
- **Telegram** : questions sur la maison depuis Telegram, alertes (nouveau problème, problème résolu) et résumé journalier.
- **Home Assistant** : recopie des pièces, des noms, du masquage et des éléments dans Home Assistant, pour les entités que les sources DKNR y déclarent déjà.
- **Historique** des valeurs dans InfluxDB.
- **Sauvegarde et restauration** de la configuration, en choisissant les données à exporter.


## Matériel requis

Le matériel exact dépend de l'installation, mais l'utilisation du projet nécessite généralement :

* un serveur MQTT, partagé avec les autres projets DKNR.
* au moins un projet DKNR publiant des entités (ex : [DKNR Zigbee](https://github.com/dknr-domotic/dknr-zigbee)).
* une machine exécutant le logiciel docker.


## Installation

Des images Docker prêtes à l'emploi sont disponibles.
Le fichier docker-compose.yaml à la racine du dépôt lance **InfluxDB** et **DKNR Domotic**. Fournissez les variables d'environnement suivantes :

* **DKNR_USERNAME** : login de l'interface node-red et d'InfluxDB.
* **DKNR_PASSWORD** : mot de passe de l'interface node-red et d'InfluxDB.
* **DKNR_SECRET**   : un mot secret pour encrypter les credits, utilisé aussi comme jeton d'InfluxDB.
* **DKNR_ADMIN_PASSWORD** (facultatif) : mot de passe du compte `admin` du tableau de bord. À défaut, c'est **DKNR_PASSWORD**.
* **DKNR_TELEGRAM_TOKEN** (facultatif) : jeton du bot Telegram. Sans lui, Telegram est désactivé.
* **DKNR_TELEGRAM_ID** (facultatif) : numéro de chat Telegram du compte `admin`.
* **DKNR_TELEGRAM_SUMMARY** (facultatif) : heure du résumé journalier, `20:00` par défaut, `off` pour ne pas l'envoyer.
* **DKNR_HA_URL** (facultatif) : adresse de Home Assistant, ex. `http://192.168.1.10:8123`. Sans elle, le miroir Home Assistant est désactivé.
* **DKNR_HA_TOKEN** (facultatif) : jeton d'accès longue durée de Home Assistant. Sans lui, le miroir Home Assistant est désactivé.

Le mot de passe du compte `admin` du tableau de bord ne se change pas dans l'interface : il est appliqué à chaque démarrage depuis ces variables. Pour le changer, modifiez la variable et redémarrez le conteneur.

Le tableau de bord DKNR est disponible sur `http://<ip du serveur docker>:1880/dashboard` et l'éditeur Node-RED sur `http://<ip du serveur docker>:1880/admin`.


## Configuration

### MQTT

Dans la page **Configuration** :

* **Adresse IP**, **port**, **utilisateur** et **mot de passe** du serveur MQTT, le même que celui des autres projets DKNR.
* **Topic** : racine des topics DKNR (`dknr` par défaut).

### Pièces et entités

1. Créez les pièces dans la page **Configuration** : l'identifiant ne contient que des lettres minuscules, des chiffres et `_` (ex : `salle_de_bain`), et ne change plus ensuite ; le nom accepte les lettres accentuées, les chiffres, les espaces et `- ' . ( )`. Placez-les ensuite sur le plan depuis la page **Pièces**.
2. Dans la page **Entités**, choisissez une source puis, pour chaque entité utile, donnez-lui une pièce et un élément (lumière, volet, porte, température...). Une nouvelle entité est cachée tant qu'elle n'est pas configurée.
3. Dans la page **Pièces**, renseignez les jours travaillés et les heures de confort de chaque pièce (utilisés par le chauffage et les scènes).
4. Dans la page **Energie**, choisissez les entités de puissance, de batterie, de compteurs et de tarif.


## Scènes

Une scène pilote une entité cible (lumière, volet, serrure, chauffe-eau, thermostat, ventilation) à partir d'une ou plusieurs entités déclencheurs. Pour chaque déclencheur, on choisit les valeurs d'entrée haute et basse et la sortie correspondante (niveau haut, niveau bas, inverser ou aucune). L'ordre passe ensuite par une suite de routines, selon l'élément de la cible :

* **Modes** : automatisme général, scène activée, mode manuel de l'élément.
* **Moments** : uniquement la nuit ou le jour, aux heures de confort ou d'éco de la pièce.
* **Luminosité** : uniquement s'il fait assez sombre ou assez clair.
* **Présence** : mouvement, maintien allumé tant que le mouvement continue.
* **Ouvertures** : aucun ordre tant qu'une porte, une fenêtre ou une baie est ouverte, l'ordre bloqué est rejoué à sa fermeture.
* **Humidité**, **veilleuse**, **tarif** favorable, **puissance** consommée (arrêt quand l'appareil ne consomme plus).
* **Quotidien** : une seule fois par jour.
* **Durée** : arrêt automatique après un délai, aussi après un allumage manuel.
* **Thermostat** : consigne confort, éco ou hors gel, sondes intérieures (déclencheurs de la scène) et température extérieure (une ou deux sondes choisies dans la page **Energie**, menu Entités, qui déclenchent toutes les scènes thermostat : inutile de les ajouter aux déclencheurs), durée de chauffe calculée, arrêt fenêtre ouverte, refroidissement sur énergie solaire.

Les modes de la source `dknr` (ex : `dknr/sensor/nycthemer` pour le jour / la nuit) peuvent servir de déclencheurs.


## MQTT

Avec le topic `dknr` par défaut :

* `dknr/discovery/<source>`, `dknr/discovery/<source>/<parent>`, `dknr/discovery/<source>/<parent>/<entité>` : description des sources, appareils et entités, lue pour créer les entités.
* `dknr/get/<source>/<parent>/<entité>` : valeurs lues. Les états binaires valent `1` ou `0`, les listes utilisent la clé de l'option.
* `dknr/set/<source>/<parent>/<entité>` : commandes envoyées par les pièces et les scènes.
* `dknr/room/<source>/<parent>/<entité>` : pièce de chaque entité (identifiant), publiée en retenu pour les autres projets DKNR.
* `dknr/data/room/<id>/name` et `dknr/data/room/<id>/outdoor` : nom de chaque pièce et `1` si elle est extérieure.

DKNR Domotic est lui-même la source `dknr` : ses modes et capteurs internes sont publiés et pilotés par les mêmes topics (ex : `dknr/set/dknr/command/light` avec `auto`, `high`, `low` ou `manual`).


## Assistant (MCP)

DKNR Domotic expose un serveur [MCP](https://modelcontextprotocol.io) en lecture seule sur `http://<ip du serveur docker>:1880/mcp`, pour qu'un assistant comme Claude lise l'installation : pièces, entités, historique, scènes et le détail de leur dernier échec, entités muettes et alertes. Il ne pilote rien.

1. Connectez-vous au tableau de bord (niveau parent ou administrateur), page **Authentification**, et cliquez sur **Nouvelle clé MCP**. Copiez la clé : elle n'est affichée qu'une fois. **Retirer la clé** la désactive aussitôt.
2. Déclarez le serveur dans votre client MCP avec la clé dans l'en-tête `x-api-key` (ou `Authorization: Bearer <clé>`). Par exemple avec Claude Code : `claude mcp add --transport http dknr http://<ip>:1880/mcp --header "x-api-key: <clé>"`.

La clé donne les droits de son utilisateur, ni plus ni moins. Le serveur est fait pour le réseau local : ne l'ouvrez pas vers internet sans proxy HTTPS.


## Telegram

DKNR Domotic peut répondre à des questions sur la maison depuis Telegram et y envoyer des alertes et un résumé journalier. Le bot ne fait que des appels sortants vers Telegram : rien à ouvrir depuis internet.

1. Créez un bot avec [@BotFather](https://t.me/BotFather) et mettez son jeton dans **DKNR_TELEGRAM_TOKEN**.
2. Écrivez au bot depuis Telegram : s'il ne vous connaît pas, il répond avec votre numéro de chat.
3. Mettez ce numéro dans **DKNR_TELEGRAM_ID** pour le compte `admin` (puis redémarrez le conteneur), ou dans le champ **Telegram** d'un utilisateur (page **Configuration**).

Un compte lié reçoit tout : les alertes et le résumé journalier. Les questions suivent les droits de son niveau, comme le tableau de bord.

* Commandes : `/maison`, `/pieces`, `/piece nom`, `/cherche texte`, `/problemes`, `/scenes`, `/resume` (en anglais : `/house`, `/rooms`, `/room`, `/search`, `/problems`, `/scenes`, `/summary`). Un nom de pièce ou un texte sans commande marche aussi.
* Alertes : entités muettes, piles faibles, alertes actives (dont les défauts des sources), scènes en erreur. Un message quand un problème apparaît, un autre quand il est résolu.
* Résumé journalier : températures du jour des sondes extérieures choisies dans la page **Energie**, prévision du lendemain, énergie du jour et ce qui reste à vérifier.

Un seul conteneur doit utiliser un même jeton : un second conteneur (de test par exemple) a besoin de son propre bot.


## Home Assistant

Les sources DKNR (dknr-zigbee, dknr-zwave, dknr-rfxcom...) déclarent elles-mêmes leurs entités à Home Assistant par la discovery MQTT : elles s'utilisent aussi avec Home Assistant sans DKNR Domotic. DKNR Domotic ne publie rien de plus sur MQTT, il n'y a donc pas de doublon. Il range les entités déjà déclarées dans Home Assistant comme dans le tableau de bord, par l'API WebSocket de Home Assistant :

* **zone** : la pièce de l'entité (les zones manquantes sont créées, `> Home` devient `Home`) ;
* **nom** : le nom donné dans DKNR Domotic ;
* **masquage** : une entité cachée ou bloquée dans DKNR Domotic est masquée dans Home Assistant (pas désactivée ni supprimée) ;
* **étiquette** : une étiquette par élément (Lumière, Volet, Température...), dans la langue du compte `admin`. Les autres étiquettes de l'entité sont conservées.

Mise en place :

1. Dans Home Assistant, page de votre profil, onglet **Sécurité**, créez un **jeton d'accès longue durée**.
2. Mettez l'adresse de Home Assistant dans **DKNR_HA_URL** et le jeton dans **DKNR_HA_TOKEN**, puis redémarrez le conteneur.

La recopie a lieu une minute après le démarrage puis toutes les 5 minutes, et n'envoie que les différences. Elle ne touche qu'aux entités dont l'identifiant unique commence par `dknr_` (celles des sources DKNR) : DKNR Domotic garde la main sur leur zone, leur nom, leur masquage et leurs étiquettes d'élément. Les scènes restent dans DKNR Domotic.

Quand une source a changé le type d'une entité, Home Assistant garde l'ancienne entité (indisponible) à côté de la nouvelle : DKNR Domotic ne recopie que celle qui fonctionne et masque les autres. Vous pouvez supprimer ces anciennes entités dans Home Assistant.


## A faire

* Délestage des thermostats quand la puissance dépasse l'abonnement électrique.


## Contribuer

Ce projet est **open-source**, vous pouvez participer en créant des [tickets](https://github.com/dknr-domotic/dknr-domotic/issues) ou en proposant de [requêtes](https://github.com/dknr-domotic/dknr-domotic/pulls) sur le dépôt github du projet.


## Voir aussi

- [DKNR Zigbee](https://github.com/dknr-domotic/dknr-zigbee)
- [DKNR Z-Wave](https://github.com/dknr-domotic/dknr-zwave)
- [DKNR RFXCom](https://github.com/dknr-domotic/dknr-rfxcom)
- [DKNR Teleinfo](https://github.com/dknr-domotic/dknr-teleinfo)
- [DKNR Nuki](https://github.com/dknr-domotic/dknr-nuki)
- [DKNR Daikin](https://github.com/dknr-domotic/dknr-daikin)
- [DKNR Zendure](https://github.com/dknr-domotic/dknr-zendure)
- [DKNR APSystems](https://github.com/dknr-domotic/dknr-apsystems)
