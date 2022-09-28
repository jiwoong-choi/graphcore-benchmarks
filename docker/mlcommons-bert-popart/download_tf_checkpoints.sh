mkdir -p tf-checkpoints/bs64k_32k_ckpt
cd tf-checkpoints/bs64k_32k_ckpt

function gdrive-download () {
  CONFIRM=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$1" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')
  wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$CONFIRM&id=$1" -r -O $2
  rm -rf /tmp/cookies.txt
}

gdrive-download 1Q47V3K3jFRkbJ2zGCrKkKk-n0fvMZsa0 model.ckpt-28252.index
gdrive-download 1vAcVmXSLsLeQ1q7gvHnQUSth5W_f_pwv model.ckpt-28252.meta
gdrive-download 1chiTBljF0Eh1U5pKs6ureVHgSbtU8OG_ model.ckpt-28252.data-00000-of-00001
