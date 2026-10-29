package com.juan.api_delivery.endereco;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EnderecoRepository extends JpaRepository<Endereco, Long> {
    List<Endereco> findByUsuarioId(Long usuarioId);
}
