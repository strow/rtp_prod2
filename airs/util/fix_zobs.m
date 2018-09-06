function prof = fix_zobs(prof)

iz = prof.zobs < 20000 & prof.zobs > 20;
prof.zobs(iz) = prof.zobs(iz) * 1000;

