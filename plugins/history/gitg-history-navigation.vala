namespace GitgHistory
{
	private class Navigation : Object, GitgExt.Navigation
	{
		public GitgExt.Application? application { owned get; construct; }

		public Navigation(GitgExt.Application app)
		{
			Object(application: app);
		}

		private static int sort_refs(Gitg.Ref a, Gitg.Ref b)
		{
			return a.parsed_name.shortname.ascii_casecmp(b.parsed_name.shortname);
		}

		public void populate(GitgExt.NavigationTreeModel model)
		{
			var repo = application.repository;

			List<Gitg.Ref> branches = new List<Gitg.Ref>();
			HashTable<string, List<Gitg.Ref>> remotes;
			List<string> remotenames = new List<string>();

			remotes = new HashTable<string, List<Gitg.Ref>>(str_hash, str_equal);

			try
			{
				repo.references_foreach(Ggit.RefType.LISTALL, (nm) => {
					Gitg.Ref? r;

					try
					{
						r = repo.lookup_reference(nm);
					} catch { return 0; }

					if (r.parsed_name.rtype == Gitg.RefType.BRANCH)
					{
						branches.insert_sorted(r, sort_refs);
					}
					else if (r.parsed_name.rtype == Gitg.RefType.REMOTE)
					{
						unowned List<Gitg.Ref> lst;

						string rname = r.parsed_name.remote_name;

						if (!remotes.lookup_extended(rname, null, out lst))
						{
							List<Gitg.Ref> nlst = new List<Gitg.Ref>();
							nlst.prepend(r);

							remotes.insert(rname, (owned)nlst);
							remotenames.insert_sorted(rname, (a, b) => a.ascii_casecmp(b));
						}
						else
						{
							/*unowned List<Gitg.Ref> start = lst;

							lst.insert_sorted(r, sort_refs);

							if (lst != start)
							{
								remotes.insert(rname, lst.copy());
							}*/
						}
					}

					return 0;
				});
			} catch {}

			Gitg.Ref? head = null;

			try
			{
				head = repo.get_head();
			} catch {}

			// Branches
			model.begin_header("Branches", null);

			foreach (var item in branches)
			{
				if (head != null && item.get_id().equal(head.get_id()))
				{
					model.append_default(item.parsed_name.shortname,
					                     "object-select-symbolic",
					                     null);
				}
				else
				{
					model.append(item.parsed_name.shortname, null, null);
				}
			}

			model.end_header();

			// Remotes
			model.begin_header("Remotes", "network-server-symbolic");

			foreach (var rname in remotenames)
			{
				//model.append(item.parsed_name.remote_branch, null, null);
			}

			model.end_header();

			// Tags
		}

		public GitgExt.NavigationSide navigation_side
		{
			get { return GitgExt.NavigationSide.LEFT; }
		}

		public bool available
		{
			get { return true; }
		}
	}
}

// ex: ts=4 noet