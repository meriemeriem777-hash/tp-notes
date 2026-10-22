# Compte rendu : TP Pipeline DevSecOps

Dépôt : https://github.com/meriemeriem777-hash/tp-notes

## Mesures avant / après durcissement de l'image

| Mesure | Version naïve | Version durcie |
|---|---|---|
| Taille de l'image | 1640 Mo | 243 Mo |
| Vulnérabilités HIGH + CRITICAL (Trivy) | 578 | 11 |
| Contrôles Checkov échoués | 2 | 0 |
| Utilisateur du conteneur | root | node |

## Dépendances et SBOM

- Dépendances directes : 1 (express). Paquets dans l'arbre complet : 128.
- npm audit : 0 vulnérabilité.
- SBOM du code source : 69 composants. SBOM de l'image : 285 composants.
- Dependabot configuré (npm, docker, github-actions) et alertes activées.

## Secrets

- Gitleaks sur le dépôt : 0 fuite.
- Avec un faux jeton (demo.env) : 1 fuite détectée, règle github-pat.
- Le hook pre-commit a refusé le commit contenant le faux jeton.

## SAST (Semgrep)

- 75 règles exécutées, 0 alerte sur le code.
- Avec le Dockerfile naïf : 1 alerte.

## Pipeline et portes

- Pipeline complet (6 jobs) vert sur main : durée totale 58 s, job le plus long : image (29 s).
- Porte n°1 (image de base node:16-alpine, en fin de vie) : job image en échec (Trivy), pull request bloquée.
- Porte n°2 (Dockerfile naïf) : jobs iac et sast en échec, image ignoré, pull request bloquée.
- La règle de protection de main exige désormais le statut image.
- Les deux branches de test ont été fermées sans fusion puis supprimées.

## Tri d'alertes

Alerte la plus difficile à classer : busybox, sévérité haute (CVSS 7,5). Aucun correctif n'est publié et l'API n'appelle jamais de commande système : vrai positif à faible risque réel, classé au backlog avec surveillance. La décision repose sur l'exposition, la présence d'un correctif et l'usage réel du composant, pas sur le score seul.

## Synthèse

Contrôles placés sur la boucle DevOps :
- Code : hook pre-commit avec Gitleaks (secrets) et Semgrep (SAST).
- Build : npm audit (SCA), SBOM, Checkov (Dockerfile).
- Test : tests unitaires (job build-test).
- Release : Trivy sur l'image comme porte de blocage, et protection de main.

Étapes sans contrôle : Plan (pas de modélisation des menaces), test dynamique (pas de DAST), Deploy (pas de signature d'image ni de politique d'admission), Operate et Monitor (pas de surveillance ni de nouveau scan planifié).

Contrôle que j'ajouterais : un scan DAST (OWASP ZAP en mode baseline) sur un conteneur de l'API lancé dans le pipeline. Tous mes contrôles actuels sont statiques ; un DAST testerait l'application en fonctionnement (en-têtes de sécurité, comportement des routes, gestion des erreurs).

## Remarques

- Le réseau de l'environnement était instable : npm échouait dans les conteneurs Alpine (ECONNRESET) et les DNS de Docker ont été remplacés par celui de la VM. L'image locale a été construite en copiant les dépendances installées sur la VM, au lieu du multi-stage prévu.
- Dans le pipeline GitHub, le job image bloquait sur 10 vulnérabilités HIGH venant de npm, inclus dans l'image de base node:22-alpine. L'API n'en a pas besoin : npm est retiré de l'image finale, et le job est repassé au vert.
- npm audit donnait 0 alerte, alors que le scan de l'image en trouvait 10 : l'image embarque aussi les outils de la base, pas seulement les dépendances du projet.
