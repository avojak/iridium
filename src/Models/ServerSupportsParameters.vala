/*
 * Copyright (c) 2020 Andrew Vojak (https://avojak.com)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Andrew Vojak <andrew.vojak@gmail.com>
 */

public class Iridium.Models.ServerSupportsParameters : GLib.Object {

    private ServerSupportsParameters () {
        Object ();
    }

    public const string PREFIX = "PREFIX";
    public const string CHANTYPES = "CHANTYPES";
    public const string CHANMODES = "CHANMODES";
    public const string MODES = "MODES";
    public const string MAXCHANNELS = "MAXCHANNELS";
    public const string CHANLIMIT = "CHANLIMIT";
    public const string NICKLEN = "NICKLEN";
    public const string MAXBANS = "MAXBANS";
    public const string MAXLIST = "MAXLIST";
    public const string NETWORK = "NETWORK";
    public const string EXCEPTS = "EXCEPTS";
    public const string INVEX = "INVEX";
    public const string WALLCHOPS = "WALLCHOPS";
    public const string WALLVOICES = "WALLVOICES";
    public const string STATUSMSG = "STATUSMSG";
    public const string CASEMAPPING = "CASEMAPPING";
    public const string ELIST = "ELIST";
    public const string TOPICLEN = "TOPICLEN";
    public const string KICKLEN = "KICKLEN";
    public const string CHANNELLEN = "CHANNELLEN";
    public const string CHIDLEN = "CHIDLEN";
    public const string IDCHAN = "IDCHAN";
    public const string STD = "STD";
    public const string SILENCE = "SILENCE";
    public const string RFC2812 = "RFC2812";
    public const string PENALTY = "PENALTY";
    public const string FNC = "FNC";
    public const string SAFELIST = "SAFELIST";
    public const string AWAYLEN = "AWAYLEN";
    public const string NOQUIT = "NOQUIT";
    public const string USERIP = "USERIP";
    public const string CPRIVMSG = "CPRIVMSG";
    public const string CNOTICE = "CNOTICE";
    public const string MAXNICKLEN = "MAXNICKLEN";
    public const string MAXTARGETS = "MAXTARGETS";
    public const string KNOCK = "KNOCK";
    public const string VCHANS = "VCHANS";
    public const string WATCH = "WATCH";
    public const string WHOX = "WHOX";
    public const string CALLERID = "CALLERID";
    public const string ACCEPT = "ACCEPT";
    public const string LANGUAGE = "LANGUAGE";

}