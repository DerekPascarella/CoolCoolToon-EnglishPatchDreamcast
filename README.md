<h1>Cool Cool Toon</h1>
<img width="169" height="165" align="right" src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/cover.png?raw=true">Download the English translation patch (more information in the <a href="#patching-instructions">Patching Instructions</a> section).
<br><br>
<ul>
 <li><b>GDI Format (Users of ODEs or Emulators)</b><br>Download <a href="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/releases/download/1.1/Cool.Cool.Toon.English.v1.1.dcp">Cool Cool Toon (English v1.1).dcp</a> for use with <a href="https://github.com/DerekPascarella/UniversalDreamcastPatcher">Universal Dreamcast Patcher</a> v1.3 or newer.</li>
 <br>
 <li><b>CDI Format (Users Burning to CD-R)</b><br>Download <a href="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/releases/download/1.1/Cool.Cool.Toon.English.v1.1.xdelta">Cool Cool Toon (English v1.1).xdelta</a> for use with <a href="https://www.romhacking.net/utilities/704/">Delta Patcher</a> (or equivalent tools).</li>
</ul>

<h2>Table of Contents</h2>

1. [Patching Instructions](#patching-instructions)
2. [Credits](#credits)
3. [Release Changelog](#release-changelog)
4. [Reporting Bugs and Typos](#reporting-bugs-and-typos)
5. [What's Changed](#whats-changed)
6. [Launch Trailer](#launch-trailer)
7. [About the Game](#about-the-game)
8. [Bonus Content](#bonus-content)
9. [Original Soundtrack](#original-soundtrack)
10. [Neo Geo Pocket Color Link Feature](#neo-geo-pocket-color-link-feature)
11. [Tutorials](#tutorials)

<h2>Patching Instructions</h2>
<ul>
 <li><b>GDI Format (Users of ODEs or Emulators)</b><br><img align="right" width="250" src="https://github.com/DerekPascarella/UniversalDreamcastPatcher/blob/main/screenshots/screenshot.png?raw=true">The DCP patch file shipped with this release is designed for use with <a href="https://github.com/DerekPascarella/UniversalDreamcastPatcher">Universal Dreamcast Patcher</a> v1.3 or newer.  Note that Universal Dreamcast Patcher supports both TOSEC-style GDI and Redump-style CUE disc images as source input.<br><br><ol type="1"><li>Click "Select GDI or CUE" to open the source disc image.</li><li>Click "Select Patch" to open the DCP patch file.</li><li>Click "Apply Patch" to generate the patched GDI, which will be saved in the folder from which the application is launched.</li><li>Click "Quit" to exit the application.</li></ol></li>
 <br>
 <li><b>CDI Format (Users Burning to CD-R)</b><br><img align="right" width="250" src="https://i.imgur.com/r4b04e7.png">The XDelta patch file shipped with this release can be used with any number of Delta utilities, such as <a href="https://www.romhacking.net/utilities/704/">Delta Patcher</a>. Ensure the source CDI has an MD5 checksum of <tt>ABA9C3600EBDD4FBE292ABA87B43630B</tt>.<br><br><ol type="1"><li>Click the settings icon (appears as a gear) and enable "Backup original file" and "Checksum validation".</li><li>Click the "Original file" browse icon and select the unmodified CDI.</li><li>Click the "XDelta patch" browse icon and select the XDelta patch.</li><li>Click "Apply patch" to generate the patched CDI in the same folder containing the original CDI.</li><li>Verify that the patched CDI has an MD5 checksum of <tt>6A2C77A36EA8E07960BE3B12C93CAF21</tt>.</ol></li>
</ul>

<h2>Credits</h2>
<ul>
 <li><b>Programming</b></li>
  <ul>
   <li>Derek Pascarella (ateam)</li>
  </ul>
  <br>
  <li><b>Translation</b></li>
  <ul>
   <li>rio de popomocco</li>
   <li>Cargodin</li>
  </ul>
  <br>
  <li><b>Editing</b></li>
  <ul>
   <li>rio de popomocco</li>
   <li>Cargodin</li>
   <li>Derek Pascarella (ateam)</li>
   <li>James Tocchio (GGDreamcast.com)</li>
  </ul>
  <br>
  <li><b>Graphics</b></li>
  <ul>
   <li>Yuvi</li>
  </ul>
  <br>
  <li><b>Playtesting</b></li>
  <ul>
   <li>rio de popomocco</li>
   <li>Derek Pascarella (ateam)</li>
   <li>James Tocchio (GGDreamcast.com)</li>
  </ul>
  <br>
  <li><b>Special Thanks</b></li>
  <ul>
   <li>nanashi</li>
  </ul>
</ul>

<h2>Release Changelog</h2>
<ul>
 <li><b>Version 1.1 (2023-07-31)</b></li>
 <ul>
  <li>Added support for using RGB or composite on PAL consoles.</li>
 </ul>
 <li><b>Version 1.0 (2023-07-28)</b></li>
 <ul>
  <li>Initial release.</li>
 </ul>
</ul>

<h2>Reporting Bugs and Typos</h2>
Even after extensive testing on both real hardware and on emulators, the presence of bugs or typos may be possible. Should a player encounter any such issue, it's kindly requested that they <a href="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/issues/new">submit a new issue</a> to this project page, including as much detailed information as possible.

<h2>What's Changed</h2>
<img align="right" width="267" height="200" src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/screenshot.png?raw=true">Below is a high-level list of changes implemented for this English translation patch.
<br><br>
<ul>
 <li>A variable-width font has been implemented.</li>
 <li>All textures/graphics have been translated into English and re-rendered.</li>
 <li>All in-game dialogue text has been translated and appears in English.</li>
 <li>All in-game cutscenes have been translated and subtitled in English.</li>
 <li>All unlockable character and costume names have been translated and appear in English.</li>
 <li>All mini-games have been translated and appear in English.</li>
 <li>All menu text/graphics has been translated and appears in English.</li>
 <li>VMU save file metadata has been translated and appears in English.</li>
 <li>Neo Geo Pocket Color link (for use with "Cool Cool Jam") messages have been translated and appear in English (see <a href="#neo-geo-pocket-color-link-feature">Neo Geo Pocket Color Link Feature</a> section).</li>
 <li>Broken 50hz mode when game detects PAL console with a non-VGA video cable has been fixed, now defaulting to 60hz NTSC (read more in <a href="https://twitter.com/DerekPascarella/status/1685997122502426624">this Twitter post</a>).</li>
 <li>The built-in "INTERNET GATE" has been replaced with special bonus content (see <a href="#bonus-content">Bonus Content</a> section).</li>
  <ul>
   <li>Previously this portion of the game was inaccessible to those who've never configured ISP settings on their Dreamcast, but this requirement has been removed.</li>
  </ul>
</ul>

<h2>Launch Trailer</h2>
Watch the exciting launch trailer made by project team member James Tocchio of <a href="https://www.ggdreamcast.com/">GGDreamcast.com</a>.
<br><br>
<a href="https://www.youtube.com/watch?v=dhnJ5VBaKQ4"><img border="0" src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/trailer.jpg?raw=true"></a>

<h2>About the Game</h2>
<table>
<tr>
<td><b>Title</b></td>
<td>Cool Cool Toon (クルクルトゥーン)</td>
</tr>
<tr>
<td><b>Developer</b></td>
<td>SNK</td>
</tr>
<tr>
<td><b>Publisher</b></td>
<td>SNK</td>
</tr>
<tr>
<td><b>Release Date</b></td>
<td>2000-08-10</td>
</tr>
<tr>
<td><b>Supported Peripherals</b></td>
<td>VGA Box, Jump Pack, Controller, VMU, Setsuzoku Cable (Link Cable), Maracas (Unofficially)</td>
</table>
<br>
"Cool Cool Toon" (クルクルトゥーン) is an interactive 3D rhythm-comic game developed by SNK for the Dreamcast, making it one of the last games the company developed for the console. The title is also capable of linking with its Neo Geo Pocket Color companion title, "Cool Cool Jam". Both titles were released on August 10th, 2000 in Japan. The games were never licensed or localized to any other country.
<br><br>
The gameplay has often been compared with another rhythm game at the time, "Space Channel 5", by fans and critics alike. Main visuals and character designs were done by comic book artist and illustrator, Ippei Gyoubu.
<br><br>
References to the game and some of its characters were later featured in one of the stages in "Neo Geo Battle Coliseum". 
<br><br>
In 2014, SNK Playmore released the mobile game "The Rhythm of Fighters", which features a similar gameplay.

<h2>Bonus Content</h2>
<img align="right" width="267" src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/bonus.gif?raw=true">Unique and brand-new for this patch is a collection of bonus content for players to enjoy. To access this content, select "INTERNET GATE" from the main menu, which will launch a <a href="https://www.dreamcast-talk.com/forum/viewtopic.php?t=14611">modified version of the Dream Passport web browser</a>.
<br><br>
To return to the game from the bonus content section, press L on the controller, then select "EXIT TO GAME".
<br><br>
<ul>
 <li><b>100% Unlocked Save</b><br>A save file that can be downloaded directly to your VMU to unlock all stages, outfits, songs, and more! Note that this will prevent you from playing through Amp and Spica's stories from the beginning.</li>
 <br>
 <li><b>On-Disc Extras Page</b><br>The retail GD-ROM of "Cool Cool Toon" included a built-in "Omake", or "Extras", webpage. This baked-in page features fantastic artwork, including character portraits, artwork development pieces, title screens, wallpapers, and more!</li>
 <br>
 <li><b>Original Dricas Website</b><br>Dricas, the Japanese Dreamcast network website, hosted individual pages for a slew of games during the console's lifespan. Included here is the original "Cool Cool Toon" site, fully intact. For purposes of preservation, this content has been left untranslated.</li>
 <br>
 <li><b>Using Maracas</b><br>This game's little-known support for the Dreamcast maracas was documented on the retail GD-ROM itself. That documentation has been fully translated for all the crazy Dreamcast peripheral owners out there to try!</li>
</ul>

<h2>Original Soundtrack</h2>
<img align="right" width="165" height="165" src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/ost.jpg?raw=true">On September 20th, 2000, <a href="https://vgmdb.net/org/1364">Scitron Discs</a> published an original soundtrack for the game, featuring a total of 31 tracks. All "flitz battle" songs heard throughout "Cool Cool Toon" are present, including additional music from other parts of the game.
<br><br>
To learn more about the soundtrack, including credits for songwriters, music arrangers, and vocalists, visit its entry on <a href="https://vgmdb.net/album/1628">VGMdb</a>.
<br><br>
<a href="https://mega.nz/folder/OJlmgZRD#IC8D6X6UMhiI_JH96IQF2Q">Download</a> the soundtrack in MP3 format.

<h2>Neo Geo Pocket Color Link Feature</h2>
<img align="right" width="202" height="250" src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/link_cable.jpg?raw=true">A special <a href="https://segaretro.org/Neo_Geo_Pocket/Dreamcast_Setsuzoku_Cable">"Setsuzoku Cable"</a> (Link Cable) is required to make use of this feature, connecting the Neo Geo Pocket Color to the Dreamcast.
<br><br>
The companion game to "Cool Cool Toon" (called "Cool Cool Jam") for the Neo Geo Pocket Color follows the adventures of Wav and Midi in Musey Town, a neighboring city of Cool Cool Town. The main focus of this game is to start a band to find the way back home, using mini-games where the player needs to compose pieces with instruments.
<br><br>
Points earned in this game can be transferred to "Cool Cool Toon" on the Dreamcast, allowing players to unlock more costumes and characters. Conversely, unlocked characters and constumes from "Cool Cool Toon" on the Dreamcast can be transferred to "Cool Cool Jam" on the Neo Geo Pocket Color.

<h2>Tutorials</h2>
There are several mechanics players should learn in order to progress through the game, explained below. Note that these tutorials are also accessible from Yusa's bedroom by talking to Yusa and selecting "Flitz Tutorials".
<h3>Flitz Basics</h3>
<img src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/tutorials/flitz_basics_1.png?raw=true">
<img src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/tutorials/flitz_basics_2.png?raw=true">
<img src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/tutorials/flitz_basics_3.png?raw=true">
<img src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/tutorials/flitz_basics_4.png?raw=true">
<img src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/tutorials/flitz_basics_5.png?raw=true">
<h3>Flitz Boons</h3>
<img src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/tutorials/flitz_boons_1.png?raw=true">
<img src="https://github.com/DerekPascarella/CoolCoolToon-EnglishPatchDreamcast/blob/main/tutorials/flitz_boons_2.png?raw=true">
