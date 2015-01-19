# {%= name %} {%= badge("fury") %}

> {%= description %}

{%= include("install-global") %}

## General help 

```
{%= partial("usage.md") %}
```


## Apparmor cheat-sheet

* To pre-load some of the profiles from Ubuntu

    sudo apt-get install apparmor-profiles
    sudo apt-get install apparmor-utils

* To install a profile

    cp $profile /etc/apparmor.d

* After installing the profiles, do a 
 
    sudo service apparmor reload 

 or 

    sudo /etc/init.d/apparmor reload

* To check the profiles

    sudo apparmor_status 

## Author
{%= include("author") %}

## License
{%= copyright() %}
{%= license() %}

***

{%= include("footer") %}
