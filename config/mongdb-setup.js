rsconf = {
  _id: "ntb",
  members: [
    {
      _id: 0,
      host: "localhost:27017"
    }
  ]
}
rs.initiate(rsconf);
rs.conf();
rs.add("localhost:27018");
rs.add("localhost:27019");
rs.status();
