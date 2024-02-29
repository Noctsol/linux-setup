path=/usr/local/bin/kubectl


# check if file exists
if [ -f /usr/local/bin/kubectl  ]; then
echo exists
else
echo notexists
fi

shit fuck

if [[ $? -eq 0 ]]; then
    echo "Command succeeded"
else
    echo "Command failed"
fi


python3 --version
if [[ $? -eq 0 ]]; then
    echo "Command succeeded"
else
    echo "Command failed"
fi

if [ -x "$(command -v python3 --versions)" ];
then
echo python exists
fi

if [ -x "$(command -v terraform)" ];
then
echo python exists
else
echo thing
fi