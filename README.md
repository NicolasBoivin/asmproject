# 🔐 PasswordGen - Générateur de mots de passe en assembleur

![Langage](https://img.shields.io/badge/Langage-Assembleur%20x86__64-blue)
![Plateforme](https://img.shields.io/badge/Plateforme-Linux-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 📝 Description

PasswordGen est un générateur de mots de passe sécurisé écrit entièrement en assembleur x86_64 pour Linux. Ce projet a été développé dans le cadre de mes études en informatique pour démontrer la maîtrise de la programmation en langage d'assemblage et explorer les concepts de sécurité informatique.

À travers une interface en ligne de commande, l'application propose plusieurs méthodes de génération de mots de passe, chacune avec ses propres caractéristiques, ainsi qu'un outil d'évaluation de la robustesse des mots de passe.

## ✨ Fonctionnalités

- **Interface utilisateur interactive** en ligne de commande
- **Animation "Matrix"** pendant la génération des mots de passe
- **Plusieurs modes de génération**:
  - 🔤 Mots de passe standards (avec différents niveaux de complexité)
  - 🗣️ Mots de passe prononçables (faciles à mémoriser)
  - 👁️ Mots de passe sans caractères ambigus (évite les caractères facilement confondus comme 0/O, 1/l)
  - 📚 Phrases de passe (combinaisons de mots avec séparateurs)
- **Évaluation de la force** des mots de passe
- **Sauvegarde des mots de passe** dans des fichiers
- **Paramétrage personnalisé** de la longueur et de la composition des mots de passe

## 🛠️ Installation

### Prérequis

- Système d'exploitation Linux
- NASM (Netwide Assembler)
- ld (GNU Linker)

### Compilation

1. Clonez ce dépôt:
```bash
git clone https://github.com/votre-username/passwordgen.git
cd passwordgen
```

2. Compilez le programme:
```bash
nasm -f elf64 passwordgen.s -o passwordgen.o
ld passwordgen.o -o passwordgen
```

3. Rendez le fichier exécutable:
```bash
chmod +x passwordgen
```

## 🚀 Utilisation

Pour lancer le programme:

```bash
./passwordgen
```

### Menu principal

Le programme affiche un menu principal avec les options suivantes:

1. Générer un mot de passe standard
2. Générer un mot de passe prononçable
3. Générer un mot de passe sans caractères ambigus
4. Générer une phrase de passe
5. Évaluer la force d'un mot de passe
6. Quitter

### Types de mots de passe

#### Mots de passe standards

Propose quatre modes de génération:
- Mode personnalisé: vous définissez la longueur et le nombre de chiffres
- Mode fort: ≥12 caractères, mélange de tous les types de caractères
- Mode moyen: 8-10 caractères, principalement des lettres et quelques chiffres
- Mode faible: 6 caractères, principalement des lettres

#### Mots de passe prononçables

Génère des mots de passe en alternant consonnes et voyelles pour créer des séquences prononçables, plus faciles à mémoriser.

#### Mots de passe sans caractères ambigus

Génère des mots de passe en évitant les caractères qui peuvent être confondus visuellement (comme 0 et O, 1 et l, etc.).

#### Phrases de passe

Crée des phrases de passe en combinant des mots du dictionnaire français intégré avec des caractères spéciaux comme séparateurs.

### Sauvegarde des mots de passe

Les mots de passe générés peuvent être sauvegardés dans un dossier `passlist` créé automatiquement. Chaque mot de passe est enregistré dans un fichier avec un nom unique.

## 🔍 Détails techniques

### Architecture du code

Le programme est structuré en trois sections principales:

- **Section .data**: Contient toutes les données constantes (messages, ensembles de caractères, etc.)
- **Section .bss**: Contient les variables non initialisées (buffers, compteurs, etc.)
- **Section .text**: Contient le code exécutable

### Fonctions principales

- `matrix_effect`: Animation visuelle pendant la génération
- `generate_random_password`: Algorithme principal de génération standard
- `generate_pronounceable`: Génération de mots de passe prononçables
- `generate_unambiguous_password_func`: Génération sans caractères ambigus
- `generate_passphrase_func`: Génération de phrases de passe
- `calculate_strength`: Évaluation de la robustesse
- `save_to_file_function`: Sauvegarde dans un fichier

### Génération aléatoire

Le programme utilise un générateur congruent linéaire pour produire des nombres pseudo-aléatoires:
```assembly
random:
    mov rax, [rand_seed]
    mov rbx, 1103515245
    mul rbx
    add rax, 12345
    mov [rand_seed], rax
```

Ce générateur est initialisé avec l'horloge système pour améliorer l'imprévisibilité.

### Évaluation de la force des mots de passe

L'algorithme attribue des points selon plusieurs critères:
- Longueur du mot de passe (4 points par caractère)
- Présence de lettres minuscules (+10 points)
- Présence de lettres majuscules (+10 points)
- Présence de chiffres (+10 points)
- Présence de caractères spéciaux (+15 points)
- Bonus pour un mélange de tous les types (+15 points)

## 💡 Comment ça marche

### Exemple de génération d'un mot de passe fort

1. L'utilisateur sélectionne l'option 1 (Générer un mot de passe standard)
2. L'utilisateur choisit le mode 2 (Mot de passe fort)
3. Le programme utilise les paramètres prédéfinis:
   - Longueur: 14 caractères
   - 4 chiffres minimum
   - Pondération: 30% lettres minuscules, 30% majuscules, 40% caractères spéciaux
4. Animation Matrix pendant la génération
5. Affichage du mot de passe généré
6. Option de sauvegarde dans un fichier

## 🧠 Concepts d'assembleur utilisés

- Appels système Linux directs (`syscall`) pour les opérations d'entrée/sortie
- Manipulation directe de la mémoire
- Arithmétique binaire
- Structures de contrôle (boucles, branchements conditionnels)
- Manipulation de chaînes (via `rep` et autres instructions)
- Gestion de pile (sauvegarde/restauration de registres)

## 🌟 Points forts du projet

- Implémentation complète en assembleur sans dépendances externes
- Utilisation efficace des registres et de la mémoire
- Interface utilisateur intuitive malgré les contraintes du langage
- Diversité des algorithmes de génération de mots de passe
- Effets visuels attractifs (animation Matrix)

## 📊 Améliorations possibles

- Intégration d'un dictionnaire plus large pour les phrases de passe
- Génération de mots de passe basés sur des critères spécifiques (certains sites web)
- Interface graphique (via intégration avec d'autres langages)
- Stockage encrypté des mots de passe générés
- Support multilingue

---
