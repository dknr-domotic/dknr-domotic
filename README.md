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

Le mot de passe du compte `admin` du tableau de bord ne se change pas dans l'interface : il est appliqué à chaque démarrage depuis ces variables. Pour le changer, modifiez la variable et redémarrez le conteneur.

Le tableau de bord DKNR est disponible sur `http://<ip du serveur docker>:1880/dashboard` et l'éditeur Node-RED sur `http://<ip du serveur docker>:1880/admin`.


## Configuration

### MQTT

Dans la page **Configuration** :

* **Adresse IP**, **port**, **utilisateur** et **mot de passe** du serveur MQTT, le même que celui des autres projets DKNR.
* **Topic** : racine des topics DKNR (`dknr` par défaut).

### Pièces et entités

1. Créez les pièces dans la page **Configuration** (cochez *Extérieur* pour les pièces dont les sondes donnent la température extérieure), puis placez-les sur le plan depuis la page **Pièces**.
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
* **Thermostat** : consigne confort, éco ou hors gel, sondes intérieures et extérieures, durée de chauffe calculée, arrêt fenêtre ouverte, refroidissement sur énergie solaire.

Les modes de la source `dknr` (ex : `dknr/sensor/nycthemer` pour le jour / la nuit) peuvent servir de déclencheurs.


## MQTT

Avec le topic `dknr` par défaut :

* `dknr/discovery/<source>`, `dknr/discovery/<source>/<parent>`, `dknr/discovery/<source>/<parent>/<entité>` : description des sources, appareils et entités, lue pour créer les entités.
* `dknr/get/<source>/<parent>/<entité>` : valeurs lues. Les états binaires valent `1` ou `0`, les listes utilisent la clé de l'option.
* `dknr/set/<source>/<parent>/<entité>` : commandes envoyées par les pièces et les scènes.

DKNR Domotic est lui-même la source `dknr` : ses modes et capteurs internes sont publiés et pilotés par les mêmes topics (ex : `dknr/set/dknr/command/light` avec `auto`, `high`, `low` ou `manual`).


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
