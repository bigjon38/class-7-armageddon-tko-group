#!/bin/bash

# 1. Create the new clean directories
mkdir -p lab-01-armageddon
mkdir -p lab-02-bonus-a
mkdir -p lab-03-bonus-b

echo "--- Organizing Lab 01 (Armageddon) ---"
# Move the root Terraform files (these look like the main lab files)
mv main.tf lab-01-armageddon/ 2>/dev/null
mv variables.tf lab-01-armageddon/ 2>/dev/null
mv outputs.tf lab-01-armageddon/ 2>/dev/null

# Move the study notes to be the README
if [ -f "kamau/lab1b/Lab 1a study Armageddon.md" ]; then
    mv "kamau/lab1b/Lab 1a study Armageddon.md" "lab-01-armageddon/README.md"
    echo "Moved Armageddon notes."
fi

echo "--- Organizing Lab 02 (Bonus A) ---"
# Move the nested Bonus A terraform file and rename it to main.tf
if [ -f "kamau/class-7-armageddon-tko-group/Lab1/Lab1c/03_bonus_a.tf" ]; then
    mv "kamau/class-7-armageddon-tko-group/Lab1/Lab1c/03_bonus_a.tf" "lab-02-bonus-a/main.tf"
    echo "Moved Bonus A main.tf."
fi

# Move the Bonus A README
if [ -f "bonus_a_README.md" ]; then
    mv "bonus_a_README.md" "lab-02-bonus-a/README.md"
    echo "Moved Bonus A README."
fi

echo "--- Organizing Lab 03 (Bonus B) ---"
# Move and rename Bonus B files to standard names
[ -f bonus_b_alb.tf ]       && mv bonus_b_alb.tf       lab-03-bonus-b/alb.tf
[ -f bonus_b_variables.tf ] && mv bonus_b_variables.tf lab-03-bonus-b/variables.tf
[ -f bonus_b_outputs.tf ]   && mv bonus_b_outputs.tf   lab-03-bonus-b/outputs.tf

# Move any remaining bonus_b files (like waf, acm, etc if they exist)
mv bonus_b_*.tf lab-03-bonus-b/ 2>/dev/null

# Move the README
[ -f bonus_b_README.md ]    && mv bonus_b_README.md    lab-03-bonus-b/README.md

echo "------------------------------------------------"
echo "Organization complete!"
echo "You can now run 'terraform init' inside each lab folder."
echo "Once you verify everything is safe, you can delete the 'kamau' folder."