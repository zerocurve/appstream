/* database-builder.vala
 *
 * Copyright (C) 2012-2013 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU General Public License Version 3
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;
using Appstream;

namespace Appstream {

internal class Builder : Object {
	private Appstream.DatabaseWrite db_rw;
	private Array<Appstream.AppInfo> appList;
	private string CURRENT_DB_PATH;

	public Builder () {
		db_rw = new Appstream.DatabaseWrite ();

		// Update db path if necessary
		if (CURRENT_DB_PATH == "")
			CURRENT_DB_PATH = db_rw.database_path;

		appList = new Array<Appstream.AppInfo> ();
	}

	public Builder.path (string dbpath) {
		base ();
		CURRENT_DB_PATH = dbpath;
	}

	public void initialize () {
		db_rw.database_path = CURRENT_DB_PATH;

		// Make sure directory exists
		Utils.touch_dir (CURRENT_DB_PATH);

		db_rw.open ();
	}

	private bool run_provider (DataProvider dprov) {
		dprov.application.connect (new_application);
		return dprov.execute ();
	}

	private void new_application (Appstream.AppInfo app) {
		appList.append_val (app);
	}

	public bool refresh_cache () {
		bool ret = false;

		debug ("Refreshing AppStream cache");

#if APPSTREAM
		run_provider (new Provider.AppstreamXML ());
#endif
#if DEBIAN_DEP11
		run_provider (new Provider.DEP11 ());
#endif
#if UBUNTU_APPINSTALL
		run_provider (new Provider.UbuntuAppinstall ());
#endif

		ret = db_rw.rebuild (appList);

		if (ret)
			debug ("Cache refresh completed successfully.");
		else
			debug ("Unable to refresh AppStream cache");

		return ret;
	}
}

} // End of namespace: Uai
