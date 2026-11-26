-- =============================================================================
-- AcuerdoVecinal v2.0.1 - Visibilidad de casos anónimos para Administración
-- (La app oculta automáticamente el departamento solicitante en vista Admin)
-- =============================================================================

drop policy if exists "negociaciones_select_partes_o_admin" on public.negociaciones;
create policy "negociaciones_select_partes_o_admin"
  on public.negociaciones for select
  to authenticated
  using (
    condominio_id = public.mi_condominio_id()
    and (
      solicitante_id = auth.uid()
      or receptor_id = auth.uid()
      or lower(dpto_solicitante) = lower(public.mi_departamento())
      or lower(dpto_receptor) = lower(public.mi_departamento())
      or public.es_admin_de_condominio(condominio_id)
    )
  );
