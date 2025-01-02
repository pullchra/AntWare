# What is it?
NoMalware is a project I created to protect browsers from information-stealing malware (grabbers/stealers/rats). It moves the user information to another folder that the user chooses where it will be created and forces the browser to use the new location, making it impossible for malware to find the information from the browsers, as it is no longer in the default location.
> I added the discord app option as many users use it and a lot of malware steals the tokens saved inside the discord folders. It is in testing. 
# How To Use?
1. **Close your browser** and see in your __Task Manager__ if it is not working in the background
2. Open the powershell file and accept that it runs as an **administrator**
3. **Enter the directory** you want the new browser folder to be in
4. Choose whether you want to reverse the method or use it
5. __Choose the browser__ you want to protect
- After doing these steps, check if the folder was created in the chosen location. After that, delete the old default browser folder, which is usually located at ```%LOCALAPPDATA%```.
  
  ![image](https://github.com/user-attachments/assets/ffabc807-100f-4605-bfdb-02466c54163e)

Usually the folder you should delete would be the one with your user's files (User Data), example: **Edge** and **Chrome** or the **User Data folder** itself (the one with many files)
### Edge
```%LOCALAPPDATA%\Microsoft\Edge\User Data```
### Chrome
```%LOCALAPPDATA%\Google\Chrome\User Data```
### Brave
```%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data```
### Opera
```%LOCALAPPDATA%\Opera Software\Opera Stable```
#### Discord ( Test )
```%APPDATA%\discord```
> If your first attempt occurred an error, reconsider trying again and if the error persists run the script from the powershell editor.
# Credits and Warns
I created this project to help those who suffer from this type of malware. But as it is in testing I am not responsible if there is an error on your computer, this file messes with the folders of your browser.

**Credits for Pullchra**
