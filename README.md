# What is it?
AntWare is a project I created to protect browsers from information-stealing malware (grabbers/stealers/rats). It moves the user information to another folder that the user chooses where it will be created and forces the browser to use the new location, making it impossible for malware to find the information from the browsers, as it is no longer in the default location.
> I added the discord app option as many users use it and a lot of malware steals the tokens saved inside the discord folders. It is in testing.
# PowerShell
Before using the file, I have to warn you of some important points, PowerShell may not want to run this script because of its execution policy, you must use the code below with PowerShell in the administrator so that it lets run the code. After using the code, and the file, you should return the policy to what it was before.
### Unrestricted
> Set-ExecutionPolicy Unrestricted -Scope CurrentUser

after using AntWare, switch back to RemoteSigned or Restricted.
### RemoteSigned or Restricted
**RemoteSigned**
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

**Restricted ( pattern )**
> Set-ExecutionPolicy Restricted -Scope LocalMachine
# How To Use?
- This file like many other internet files that are for powershell is detected as virus, so to download it **disable your antvirus**.
1. **Close your browser** and see in your __Task Manager__ if it is not working in the background
2. Download the PowerShell file
3. Go into your **properties and unlock it** if necessary
4. Choose where the navegator folder will be created
5. Open the "run.bat" file and accept that it runs the pwoershell file as an **administrator**
6. **Enter the directory** you want the new browser folder to be in
7. Choose which browser/app you want to protect
8. Choose whether you want to **revert or protect** the browser/app

# Credits and Warns
I created this project to help those who suffer from this type of malware. But as it is in testing I am not responsible if there is an error on your computer, this file messes with the folders of your browser.
**Credits for Pullchra**
